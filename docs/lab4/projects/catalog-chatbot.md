# Product Catalog Chatbot with AI-Enhanced Management System

A product catalog management platform powered by **Docker Model Runner**. This system combines conversational AI and real-time processing for comprehensive catalog management.

## 🎯 System Overview

This is a complete AI-enhanced catalog management system featuring:

### 🤖 **Core AI Components**
- **Chatbot Interface** - Natural language product queries and conversations
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
- The latest version of Docker Compose

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


### Testing the Chatbot
```bash
# Test natural language queries
curl -X POST http://localhost:8082/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What are your most expensive electronics?"}'


# Test category lookup
curl http://localhost:8082/api/categories
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


