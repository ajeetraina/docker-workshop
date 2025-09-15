# Product Catalog Chatbot with AI-Enhanced Management System

An intelligent product catalog management platform powered by **Docker Model Runner**, **AI Agents**, and **Event-Driven Architecture**. This system combines conversational AI, intelligent agents, and real-time processing for comprehensive catalog management.

## 🎯 System Overview

This is a complete AI-enhanced catalog management system featuring:

### 🤖 **Core AI Components**
- **Chatbot Interface** - Natural language product queries and conversations
- **AI Agent Service** - Automated vendor evaluation, market research, and customer matching
- **MCP Gateway** - Model Context Protocol for AI tool orchestration
- **Model Runner Integration** - Local AI model execution with Llama 3.2

### 🏗️ **Complete Architecture**

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Frontend      │  │  Agent Portal   │  │  Chatbot UI     │
│   Port: 5173    │  │   Port: 3001    │  │   Port: 5174    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
        │                     │                     │
        └──────────┬──────────┴─────────┬───────────┘
                   │                    │
        ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
        │   Backend API   │  │ Agent Service   │  │ Chatbot API     │
        │   Port: 3000    │  │  Port: 7777     │  │  Port: 8082     │
        └─────────────────┘  └─────────────────┘  └─────────────────┘
                   │                    │                    │
                   └──────────┬─────────┴─────────┬──────────┘
                              │                   │
                    ┌─────────────────┐  ┌─────────────────┐
                    │  MCP Gateway    │  │  Model Runner   │
                    │  Port: 8811     │  │  (Local AI)     │
                    └─────────────────┘  └─────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │   PostgreSQL    │ │     MongoDB     │ │     Kafka       │
    │   Port: 5432    │ │   Port: 27017   │ │  Port: 9092     │
    │ (Products DB)   │ │ (Agent History) │ │ (Event Stream)  │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker Desktop with Model Runner enabled
- At least 8GB RAM (4GB+ for AI models)
- Docker Compose v2.0+

### 1. Pull Required Models
```bash
# Pull the AI model for chatbot and agents
docker model pull ai/llama3.2:1B-Q8_0
```

### 2. Start All Services
```bash
# Clone the repository
git clone https://github.com/ajeetraina/catalog-service-node-chatbot.git
cd catalog-service-node-chatbot

# Start the complete system
docker compose up -d --build
```

### 3. Access the Applications

| Service | URL | Description |
|---------|-----|-------------|
| **🤖 Chatbot Interface** | http://localhost:5174 | **Main chatbot for product queries** |
| **🏠 Main Frontend** | http://localhost:5173 | Product catalog management |
| **🔧 Agent Portal** | http://localhost:3001 | AI agent management interface |
| **📊 Kafka UI** | http://localhost:8080 | Event streaming monitoring |
| **🗄️ pgAdmin** | http://localhost:5050 | Database administration |



## 💬 Chatbot Capabilities


> **Note**: After running `sh add-products.sh`, your chatbot will have access to 50+ sample products for testing these capabilities.

### Natural Language Product Search
```
User: "Show me all electronics under $500"
Chatbot: "I found 8 electronics products under $500:

📱 iPhone SE - $399.00
   Compact smartphone with A15 Bionic chip

🎧 Sony WH-1000XM5 - $399.00  
   Industry-leading noise canceling headphones

⌚ Apple Watch - $249.00
   Advanced health and fitness tracking

[Additional products...]

Would you like details about any specific product?"
```

### Intelligent Category Browsing
```
User: "What's popular in home electronics?"
Chatbot: "Based on our catalog data:

🏠 Smart Home Category (12 products):
• Smart speakers: 4 products ($49-199)
• Security cameras: 3 products ($89-299) 
• Smart thermostats: 2 products ($149-249)
• Home automation hubs: 3 products ($99-349)

The Amazon Echo Dot and Ring Doorbell are our top sellers.
Which type of smart home device interests you?"
```

### Catalog Analytics
```
User: "Give me a summary of the catalog"
Chatbot: "Here's your catalog overview:

📊 **Catalog Statistics:**
• Total Products: 127
• Active Categories: 8
• Price Range: $9.99 - $2,499.00
• Average Price: $186.45
• New This Week: 5 products

🔥 **Top Categories:**
1. Electronics (34 products)
2. Clothing (28 products)  
3. Home & Garden (21 products)

Is there a specific category you'd like to explore?"
```

## 🤖 AI Agent System

The system includes intelligent agents powered by Model Runner:

### 🔍 **Vendor Intake Agent**
- **Purpose**: Evaluates new product submissions
- **Scoring**: 0-100 AI-powered evaluation
- **Criteria**: Product quality, market fit, pricing analysis
- **Integration**: Kafka events trigger automatic evaluation

### 📈 **Market Research Agent**  
- **Purpose**: Automated competitor analysis
- **Features**: Price comparison, feature analysis, market positioning
- **Data Sources**: Web scraping, API integrations via MCP Gateway
- **Output**: Comprehensive market reports

### 🎯 **Customer Match Agent**
- **Purpose**: Analyzes customer preferences and buying patterns
- **Intelligence**: ML-based recommendation engine
- **Personalization**: Tailored product suggestions
- **History**: Stored in MongoDB for continuous learning

### 📋 **Catalog Management Agent**
- **Purpose**: Maintains and optimizes product catalog
- **Automation**: Auto-categorization, price updates, inventory sync
- **Quality Control**: Duplicate detection, data validation
- **Optimization**: SEO improvements, description enhancement

## ⚙️ Model Runner Configuration

### Supported Models
| Model | Size | Performance | Use Case |
|-------|------|-------------|----------|
| `ai/llama3.2:1B-Q4_0` | 1GB | Fast | Chatbot, basic agents |
| `ai/llama3.2:1B-Q8_0` | 1.5GB | Balanced | **Recommended** |
| `ai/llama3.2:3B-Q4_0` | 2GB | High Quality | Complex agent tasks |

### Environment Configuration
```yaml
# Model Runner integration in compose.yaml
models:
  llama_model:
    model: ai/llama3.2:1B-Q8_0

# Services using Model Runner
chatbot-backend:
  models:
    llama_model:
      endpoint_var: MODEL_RUNNER_URL
      model_var: MODEL_RUNNER_MODEL

agent-service:
  models:
    llama_model:
      endpoint_var: MODEL_RUNNER_URL  
      model_var: MODEL_RUNNER_MODEL

mcp-gateway:
  models:
    llama_model:
      endpoint_var: MODEL_RUNNER_URL
      model_var: MODEL_RUNNER_MODEL
```

## 🔧 Core Services Deep Dive

### **Chatbot Backend** (`chatbot-backend`)
- **Port**: 8082
- **Purpose**: Natural language processing for product queries
- **AI Integration**: Direct Model Runner connection
- **Database**: PostgreSQL for product data
- **Features**: Intent recognition, smart search, conversation context

### **Agent Service** (`agent-service`) 
- **Port**: 7777
- **Purpose**: AI agents for automation and intelligence
- **Event Processing**: Kafka-based event handling
- **Databases**: PostgreSQL (catalog) + MongoDB (history)
- **Agents**: Vendor evaluation, market research, customer matching

### **MCP Gateway** (`mcp-gateway`)
- **Port**: 8811
- **Purpose**: AI tool orchestration and integration
- **Protocols**: Server-Sent Events (SSE) transport
- **Tools**: fetch, brave, resend, curl, mongodb
- **Role**: Enables agents to access external data sources

### **Backend API** (`backend`)
- **Port**: 3000  
- **Purpose**: Core catalog management API
- **Database**: PostgreSQL primary, MongoDB secondary
- **Integration**: Agent service communication
- **Features**: CRUD operations, vendor management, analytics

## 📊 Event-Driven Architecture

### Kafka Integration
```yaml
# Kafka configuration for real-time processing
kafka:
  image: apache/kafka:latest
  ports: ["9092:9092", "9093:9093"]
  
# Event flow examples:
# 1. New product → Agent evaluation → Catalog update
# 2. User query → Agent research → Enhanced response  
# 3. Price change → Market analysis → Competitive insights
```

### Event Types
- **Product Events**: Creation, updates, deletions
- **Agent Events**: Evaluation results, research findings
- **User Events**: Interactions, preferences, feedback
- **System Events**: Health checks, performance metrics

## 🗄️ Database Architecture

### **PostgreSQL** (Primary Database)
```sql
-- Core product catalog
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(10, 2),
    vendor_id VARCHAR(100),
    ai_score INTEGER, -- AI evaluation score
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vendor management
CREATE TABLE vendors (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255),
    evaluation_score INTEGER,
    status VARCHAR(20)
);
```

### **MongoDB** (Agent History)
```javascript
// Agent interaction history
{
  agentType: "vendor_evaluation",
  productId: "12345",
  evaluation: {
    score: 85,
    reasoning: "High quality, competitive pricing",
    criteria: ["quality", "price", "market_fit"]
  },
  timestamp: "2025-01-15T10:30:00Z"
}

// Customer interaction patterns
{
  sessionId: "abc123",
  interactions: [
    { query: "electronics under $200", results: 5 },
    { action: "view_product", productId: "67890" }
  ],
  preferences: ["electronics", "budget_conscious"]
}
```

## 🛠️ API Endpoints

### Chatbot API (`localhost:8082`)
```http
# Natural language chat
POST /api/chat
{
  "message": "Show me laptops for programming"
}

# Product search with filters
GET /api/products/search?q=laptop&category=electronics&maxPrice=1500

# Get conversation context
GET /api/context/{sessionId}
```

### Agent Service API (`localhost:7777`)
```http
# Trigger vendor evaluation
POST /api/agents/evaluate-vendor
{
  "vendorId": "tech_corp_001",
  "products": ["product_123", "product_456"]
}

# Get market research report
GET /api/agents/market-research/{productId}

# Customer preference analysis
POST /api/agents/analyze-customer
{
  "customerId": "user_789",
  "interactionHistory": [...]
}
```

### Main Backend API (`localhost:3000`)
```http
# Product management
GET /api/products
POST /api/products
PUT /api/products/{id}
DELETE /api/products/{id}

# Vendor management  
GET /api/vendors
POST /api/vendors
GET /api/vendors/{id}/evaluation

# Analytics
GET /api/analytics/summary
GET /api/analytics/trends
```

## 🔍 Development & Testing

### Local Development Setup
```bash
# Start infrastructure only
docker compose up postgres mongodb kafka -d

# Run services locally for development
cd chatbot-backend && npm run dev  # Port 8082
cd agent-service && npm run dev    # Port 7777  
cd backend && npm run dev          # Port 3000
```

### Health Checks
```bash
# Check all service health
curl http://localhost:3000/health   # Backend
curl http://localhost:8082/health   # Chatbot
curl http://localhost:7777/health   # Agents
curl http://localhost:8811/health   # MCP Gateway

# Check Model Runner status
docker model ls
docker model info ai/llama3.2:1B-Q8_0
```

### Testing the Chatbot
```bash
# Test natural language queries
curl -X POST http://localhost:8082/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What are your most expensive electronics?"}'

# Test product search
curl "http://localhost:8082/api/products/search?q=smartphone&maxPrice=800"

# Test category lookup
curl http://localhost:8082/api/categories
```

## 📈 Monitoring & Observability

### Service Monitoring
- **Kafka UI**: http://localhost:8080 - Event stream monitoring
- **pgAdmin**: http://localhost:5050 - Database monitoring  
- **Docker Logs**: `docker compose logs [service-name]`
- **Health Endpoints**: Built-in health checks for all services

### Performance Metrics
```bash
# Check resource usage
docker stats

# Monitor model performance
docker model stats ai/llama3.2:1B-Q8_0

# View service logs
docker compose logs -f chatbot-backend
docker compose logs -f agent-service
```

## 🚀 Adding Products & Data

### Automated Product Import
```bash
# Use the provided import script
./add-products.sh

# Or use the Node.js automation script
npm run import-products
```

### Testing with Sample Data
The system includes comprehensive sample data:
- **50+ Products** across multiple categories
- **Vendor Information** with AI evaluations
- **Mock Market Data** for agent testing
- **Customer Interaction Patterns** for recommendation testing

## 🔒 Production Considerations

### Security
- **Environment Variables**: Use Docker secrets for production
- **Network Security**: Configure proper firewall rules
- **Database Security**: Enable PostgreSQL/MongoDB authentication
- **API Security**: Implement rate limiting and authentication

### Scaling
- **Horizontal Scaling**: Multiple instances of each service
- **Database Sharding**: Partition large datasets
- **Model Optimization**: Use quantized models for performance
- **Caching**: Redis for frequently accessed data

### Deployment
```yaml
# Production environment variables
environment:
  - NODE_ENV=production
  - MODEL_RUNNER_URL=${MODEL_RUNNER_URL}
  - POSTGRES_HOST=${POSTGRES_HOST}
  - KAFKA_BROKERS=${KAFKA_BROKERS}
  - MONGODB_URI=${MONGODB_URI}
```



## 🎯 Quick Start Checklist

- [ ] **Pull AI Model**: `docker model pull ai/llama3.2:1B-Q8_0`
- [ ] **Start Services**: `docker compose up -d --build`
- [ ] **Import Products**: `./add-products.sh`
- [ ] **Test Chatbot**: Visit http://localhost:5174
- [ ] **Check Agents**: Visit http://localhost:3001  
- [ ] **Monitor System**: Visit http://localhost:8080

