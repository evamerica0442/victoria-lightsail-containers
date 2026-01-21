// ============================================================================
// Victoria SaaS - Bot Application
// ============================================================================
// Processes WhatsApp messages and handles orders
// ============================================================================

const express = require('express');
const { Client } = require('pg');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// ============================================================================
// Configuration
// ============================================================================

const config = {
  clientId: process.env.CLIENT_ID,
  clientName: process.env.CLIENT_NAME,
  whatsappNumber: process.env.WHATSAPP_NUMBER,
  currency: process.env.CURRENCY || 'ZAR',
  enableOrders: process.env.ENABLE_ORDERS === 'true',
  enablePayments: process.env.ENABLE_PAYMENTS === 'true',
  webhookSecret: process.env.WEBHOOK_SECRET,
  menuItems: JSON.parse(process.env.MENU_ITEMS || '{}'),
  businessHours: JSON.parse(process.env.BUSINESS_HOURS || '{"open":"08:00","close":"17:00"}'),
  deliveryAreas: JSON.parse(process.env.DELIVERY_AREAS || '[]'),
};

// ============================================================================
// Database Connection
// ============================================================================

const db = new Client({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'victoria',
  user: process.env.DB_USER || 'victoria',
  password: process.env.DB_PASSWORD,
});

// Connect to database with retry logic
async function connectDatabase() {
  let retries = 5;
  while (retries > 0) {
    try {
      await db.connect();
      console.log('✅ Connected to PostgreSQL database');
      await initializeDatabase();
      return;
    } catch (error) {
      console.error(`❌ Database connection failed. Retries left: ${retries - 1}`);
      console.error(error.message);
      retries--;
      if (retries === 0) throw error;
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
}

// Initialize database tables
async function initializeDatabase() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        customer_phone VARCHAR(20) NOT NULL,
        customer_name VARCHAR(100),
        items JSONB NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        delivery_address TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id SERIAL PRIMARY KEY,
        phone VARCHAR(20) UNIQUE NOT NULL,
        name VARCHAR(100),
        address TEXT,
        total_orders INTEGER DEFAULT 0,
        total_spent DECIMAL(10,2) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_phone);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at DESC);
    `);

    console.log('✅ Database tables initialized');
  } catch (error) {
    console.error('❌ Failed to initialize database:', error);
    throw error;
  }
}

// ============================================================================
// Message Handlers
// ============================================================================

function formatMenu() {
  let menu = `🐟 *${config.clientName}*\n\n`;
  menu += `📋 *Our Menu:*\n\n`;
  
  for (const [id, item] of Object.entries(config.menuItems)) {
    const symbol = getCurrencySymbol(config.currency);
    menu += `*${id}.* ${item.name} - ${symbol}${item.price.toFixed(2)}\n`;
  }
  
  menu += `\n🕐 *Hours:* ${config.businessHours.open} - ${config.businessHours.close}\n`;
  
  if (config.deliveryAreas.length > 0) {
    menu += `\n📍 *Delivery Areas:*\n${config.deliveryAreas.join(', ')}\n`;
  }
  
  menu += `\n💬 *To Order:* Send item numbers separated by commas\n`;
  menu += `*Example:* 1, 2, 3\n`;
  menu += `\n❓ Send *"help"* for more options`;
  
  return menu;
}

function formatHelp() {
  let help = `📚 *Available Commands:*\n\n`;
  help += `*menu* - View our menu\n`;
  help += `*1,2,3* - Order items by number\n`;
  help += `*hours* - Business hours\n`;
  help += `*location* - Delivery areas\n`;
  help += `*status* - Check order status\n`;
  help += `*help* - Show this message\n\n`;
  help += `Need assistance? Just send us a message! 😊`;
  
  return help;
}

function formatBusinessHours() {
  return `🕐 *Business Hours*\n\n` +
         `Open: ${config.businessHours.open}\n` +
         `Close: ${config.businessHours.close}\n\n` +
         `We look forward to serving you!`;
}

function formatDeliveryAreas() {
  if (config.deliveryAreas.length === 0) {
    return `📍 We currently offer pickup only. Delivery coming soon!`;
  }
  
  let areas = `📍 *Delivery Areas*\n\n`;
  areas += config.deliveryAreas.map(area => `✓ ${area}`).join('\n');
  areas += `\n\nNot in your area? Contact us!`;
  
  return areas;
}

async function handleOrder(customerPhone, message, customerName = null) {
  if (!config.enableOrders) {
    return '❌ Orders are currently disabled. Please contact us directly.';
  }
  
  // Check if within business hours
  if (!isWithinBusinessHours()) {
    return `⏰ We're currently closed.\n\n` +
           `Business hours: ${config.businessHours.open} - ${config.businessHours.close}\n\n` +
           `We'll be happy to take your order during business hours!`;
  }
  
  // Parse order items
  const itemIds = message.split(/[,\s]+/).filter(x => x.match(/^\d+$/));
  
  if (itemIds.length === 0) {
    return '❌ Invalid order format.\n\n' +
           'Please send item numbers like: 1, 2, 3\n\n' +
           'Send *"menu"* to see available items.';
  }
  
  // Build order
  const orderItems = [];
  let totalPrice = 0;
  
  for (const itemId of itemIds) {
    if (config.menuItems[itemId]) {
      orderItems.push({
        id: itemId,
        ...config.menuItems[itemId]
      });
      totalPrice += config.menuItems[itemId].price;
    } else {
      return `❌ Item ${itemId} not found.\n\nSend *"menu"* to see available items.`;
    }
  }
  
  if (orderItems.length === 0) {
    return '❌ No valid items found in your order.';
  }
  
  // Save order to database
  try {
    const result = await db.query(
      `INSERT INTO orders (customer_phone, customer_name, items, total_price, status) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id`,
      [customerPhone, customerName, JSON.stringify(orderItems), totalPrice, 'pending']
    );
    
    const orderId = result.rows[0].id;
    
    // Update customer stats
    await db.query(
      `INSERT INTO customers (phone, name, total_orders, total_spent)
       VALUES ($1, $2, 1, $3)
       ON CONFLICT (phone) 
       DO UPDATE SET 
         total_orders = customers.total_orders + 1,
         total_spent = customers.total_spent + $3,
         updated_at = CURRENT_TIMESTAMP`,
      [customerPhone, customerName, totalPrice]
    );
    
    // Format confirmation
    const symbol = getCurrencySymbol(config.currency);
    let confirmation = `✅ *Order Confirmed!*\n\n`;
    confirmation += `📝 Order #${orderId}\n\n`;
    confirmation += `*Items:*\n`;
    
    orderItems.forEach(item => {
      confirmation += `• ${item.name} - ${symbol}${item.price.toFixed(2)}\n`;
    });
    
    confirmation += `\n💰 *Total: ${symbol}${totalPrice.toFixed(2)}*\n\n`;
    confirmation += `📞 We'll contact you shortly to confirm delivery details.\n\n`;
    confirmation += `Thank you for your order! 🙏`;
    
    return confirmation;
    
  } catch (error) {
    console.error('Error saving order:', error);
    return '❌ Sorry, there was an error processing your order. Please try again or contact us directly.';
  }
}

async function handleStatusCheck(customerPhone) {
  try {
    const result = await db.query(
      `SELECT id, items, total_price, status, created_at 
       FROM orders 
       WHERE customer_phone = $1 
       ORDER BY created_at DESC 
       LIMIT 5`,
      [customerPhone]
    );
    
    if (result.rows.length === 0) {
      return `📋 No orders found.\n\nSend *"menu"* to place your first order!`;
    }
    
    const symbol = getCurrencySymbol(config.currency);
    let status = `📋 *Your Recent Orders:*\n\n`;
    
    result.rows.forEach(order => {
      const items = JSON.parse(order.items);
      const itemNames = items.map(i => i.name).join(', ');
      const date = new Date(order.created_at).toLocaleDateString();
      
      status += `*Order #${order.id}*\n`;
      status += `${itemNames}\n`;
      status += `${symbol}${order.total_price} - ${order.status.toUpperCase()}\n`;
      status += `${date}\n\n`;
    });
    
    return status;
    
  } catch (error) {
    console.error('Error checking status:', error);
    return '❌ Sorry, unable to retrieve order status. Please try again later.';
  }
}

function isWithinBusinessHours() {
  const now = new Date();
  const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  
  return currentTime >= config.businessHours.open && currentTime <= config.businessHours.close;
}

function getCurrencySymbol(currency) {
  const symbols = {
    'ZAR': 'R',
    'USD': '$',
    'EUR': '€',
    'GBP': '£',
  };
  return symbols[currency] || currency;
}

function getWelcomeMessage() {
  return `👋 Welcome to *${config.clientName}*!\n\n` +
         `Send *"menu"* to see what we offer\n` +
         `Send *"help"* for available commands\n\n` +
         `We're here to help! 😊`;
}

// ============================================================================
// Webhook Endpoint
// ============================================================================

app.post('/webhook', async (req, res) => {
  try {
    const { from, body, name } = req.body;
    
    if (!from || !body) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const message = body.toLowerCase().trim();
    const customerPhone = from;
    const customerName = name || null;
    
    console.log(`📱 Message from ${customerPhone}: ${message}`);
    
    let response;
    
    // Route message to appropriate handler
    if (message.includes('menu')) {
      response = formatMenu();
    } else if (message.includes('help')) {
      response = formatHelp();
    } else if (message.includes('hours')) {
      response = formatBusinessHours();
    } else if (message.includes('location') || message.includes('delivery')) {
      response = formatDeliveryAreas();
    } else if (message.includes('status') || message.includes('order')) {
      response = await handleStatusCheck(customerPhone);
    } else if (/^\d/.test(message)) {
      // Starts with number - treat as order
      response = await handleOrder(customerPhone, message, customerName);
    } else {
      // Default welcome message
      response = getWelcomeMessage();
    }
    
    console.log(`📤 Response: ${response.substring(0, 100)}...`);
    
    res.json({ 
      message: response,
      success: true 
    });
    
  } catch (error) {
    console.error('❌ Webhook error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Sorry, something went wrong. Please try again.'
    });
  }
});

// ============================================================================
// Health Check Endpoint
// ============================================================================

app.get('/health', async (req, res) => {
  try {
    // Check database connection
    await db.query('SELECT 1');
    
    res.json({
      status: 'healthy',
      service: 'victoria-bot',
      clientId: config.clientId,
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      service: 'victoria-bot',
      clientId: config.clientId,
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ============================================================================
// Metrics Endpoint (Optional)
// ============================================================================

app.get('/metrics', async (req, res) => {
  try {
    const stats = await db.query(`
      SELECT 
        COUNT(*) as total_orders,
        COUNT(DISTINCT customer_phone) as total_customers,
        SUM(total_price) as total_revenue,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_orders
      FROM orders
    `);
    
    res.json({
      clientId: config.clientId,
      clientName: config.clientName,
      ...stats.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// Start Server
// ============================================================================

const PORT = process.env.PORT || 3001;

async function start() {
  try {
    console.log('🚀 Starting Victoria Bot...');
    console.log(`📋 Client: ${config.clientName} (${config.clientId})`);
    
    // Connect to database
    await connectDatabase();
    
    // Start Express server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`✅ Bot server running on port ${PORT}`);
      console.log(`🌐 Health check: http://localhost:${PORT}/health`);
      console.log(`📊 Metrics: http://localhost:${PORT}/metrics`);
    });
    
  } catch (error) {
    console.error('❌ Failed to start bot:', error);
    process.exit(1);
  }
}

// Handle shutdown gracefully
process.on('SIGTERM', async () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully...');
  await db.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 Received SIGINT, shutting down gracefully...');
  await db.end();
  process.exit(0);
});

// Start the application
start();
