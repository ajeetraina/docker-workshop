## Prerequisite

- Docker Desktop 4.43+
- Enable Docker Offload (optional)


## Sample Compose for Agents Demos 

| Demo | Agent System | Models | MCPs | project | compose |
| ---- | ---- | ---- | ---- | ---- | ---- |
| [A2A](https://github.com/a2a-agents/agent2agent) Multi-Agent Fact Checker | Multi-Agent | OpenAI | duckduckgo | [./a2a](./a2a) | [compose.yaml](./a2a/compose.yaml) |
| [Agno](https://github.com/agno-agi/agno) agent that summarizes GitHub issues | Multi-Agent | qwen3(local) | github-official | [./agno](./agno) | [compose.yaml](./agno/compose.yaml) |
| [Vercel AI-SDK](https://github.com/vercel/ai) Chat-UI for mixing MCPs and Model | Single Agent | llama3.2(local), qwen3(local) | wikipedia-mcp, brave, resend(email) | [./vercel](./vercel) | [compose.yaml](https://github.com/slimslenderslacks/scira-mcp-chat/blob/main/compose.yaml) |
| [CrewAI](https://github.com/crewAIInc/crewAI) Marketing Strategy Agent | Multi-Agent | qwen3(local) | duckduckgo | [./crew-ai](./crew-ai) | [compose.yaml](https://github.com/docker/compose-agents-demo/blob/main/crew-ai/compose.yaml) |
| [ADK](https://github.com/google/adk-python) Multi-Agent Fact Checker | Multi-Agent | gemma3-qat(local) | duckduckgo | [./adk](./adk) | [compose.yaml](./adk/compose.yaml) |
| [ADK](https://github.com/google/adk-python) & [Cerebras](https://www.cerebras.ai/) Golang Experts | Multi-Agent | unsloth/qwen3-gguf:4B-UD-Q4_K_XL & ai/qwen2.5:latest (DMR local), llama-4-scout-17b-16e-instruct (Cerebras remote) |  | [./adk-cerebras](./adk-cerebras) | [compose.yml](./adk-cerebras/compose.yml) |
| [LangGraph](https://github.com/langchain-ai/langgraph) SQL Agent | Single Agent | qwen3(local) | postgres | [./langgraph](./langgraph) | [compose.yaml](./langgraph/compose.yaml) |
| [Embabel](https://github.com/embabel/embabel-agent) Travel Agent | Multi-Agent | qwen3, Claude3.7, llama3.2, jimclark106/all-minilm:23M-F16 | brave, github-official, wikipedia-mcp, weather, google-maps, airbnb | [./embabel](./embabel) | [compose.yaml](https://github.com/embabel/travel-planner-agent/blob/main/compose.yaml) and [compose.dmr.yaml](https://github.com/embabel/travel-planner-agent/blob/main/compose.dmr.yaml) |
| [Spring AI](https://spring.io/projects/spring-ai) Brave Search | Single Agent | none | duckduckgo | [./spring-ai](./spring-ai) | [compose.yaml](./spring-ai/compose.yaml) |
| [ADK](https://github.com/google/adk-python) Sock Store Agent | Multi-Agent | qwen3 | MongoDb, Brave, Curl,  | [./adk-sock-shop](./adk-sock-shop/) | [compose.yaml](./adk-sock-shop/compose.yaml) |
| [Langchaingo](https://github.com/tmc/langchaingo) DuckDuckGo Search | Single Agent | gemma3 | duckduckgo | [./langchaingo](./langchaingo) | [compose.yaml](./langchaingo/compose.yaml) |
