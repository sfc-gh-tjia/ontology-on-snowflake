# Soccer Graph Analytics MCP Server

A complete MCP (Model Context Protocol) server implementation for graph analytics on the Soccer Knowledge Graph. Provides 5 NetworkX-powered graph analytics tools that integrate with Cortex Agent.

## 🎯 Architecture

```
┌─────────────────────────────────────────────────┐
│  Snowflake SPCS (Container Services)            │
│  ┌───────────────────────────────────────────┐  │
│  │  Docker Container                         │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  soccer_mcp_server.py               │  │  │
│  │  │  - FastMCP framework                │  │  │
│  │  │  - NetworkX graph analytics         │  │  │
│  │  │  - HTTP endpoints (port 5000)       │  │  │
│  │  │  - 5 custom tools                   │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
         ↕ HTTP
┌─────────────────────────────────────────────────┐
│  Cortex Agent (Service Functions)               │
└─────────────────────────────────────────────────┘
```

## 📁 Files

| File | Description |
|------|-------------|
| `soccer_mcp_server.py` | Main MCP server with graph analytics tools |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container build configuration |
| `service.yaml` | SPCS service specification |
| `deploy_spcs.sh` | Deployment automation script |
| `deploy_to_spcs.sql` | Snowflake infrastructure setup |
| `spcs_service_functions.sql` | Service functions for Cortex Agent |
| `SPCS_DEPLOYMENT_GUIDE.md` | Step-by-step deployment guide |
| `graph_data/` | Static JSON data files |

## 🔧 Graph Analytics Tools

| Tool | Description |
|------|-------------|
| `graph_shortest_path` | Find shortest path between players or clubs |
| `graph_centrality_analysis` | Analyze betweenness, closeness, degree, eigenvector centrality |
| `graph_community_detection` | Detect communities using Louvain algorithm |
| `graph_transfer_network_analysis` | Analyze transfer patterns for clubs/players |
| `graph_temporal_analysis` | Analyze network evolution and trends over time |

## 🚀 Quick Start

### Option 1: Local Development (MCP STDIO Mode)

```bash
# Install dependencies
pip install -r requirements.txt

# Run MCP server (STDIO mode)
python soccer_mcp_server.py
```

### Option 2: Deploy to Snowflake SPCS

1. **Setup Snowflake Infrastructure:**
   ```sql
   -- Execute deploy_to_spcs.sql in Snowflake
   @deploy_to_spcs.sql
   ```

2. **Build and Push Docker Image:**
   ```bash
   chmod +x deploy_spcs.sh
   ./deploy_spcs.sh
   ```

3. **Create Service Functions:**
   ```sql
   -- Execute spcs_service_functions.sql in Snowflake
   @spcs_service_functions.sql
   ```

4. **Add to Cortex Agent:**
   - Navigate to: Snowsight → AI & ML → Agents → [Your Agent] → Edit → Tools → Custom tools → Add
   - Add all 5 service functions as custom tools

See `SPCS_DEPLOYMENT_GUIDE.md` for detailed instructions.

## 🔗 Integration with Cortex Agent

Once deployed, the agent can answer questions like:

- "Find the shortest path between Messi and Ronaldo"
- "Who are the top 5 most influential players by betweenness centrality?"
- "What communities exist in the player network?"
- "Show the transfer history for Real Madrid"
- "How has the transfer network evolved from 2020 to 2025?"

## 📊 Data Sources

The server uses static JSON files in `graph_data/`:
- `persons.json` - Players and coaches
- `clubs.json` - Soccer clubs
- `matches.json` - Match data
- `player_contracts.json` - Player contract history
- `coach_contracts.json` - Coach contract history
- `match_appearances.json` - Player match appearances

## 🔍 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MCP_TRANSPORT` | Transport mode (`stdio` or `http`) | `stdio` |
| `PRELOAD_ON_STARTUP` | Preload graph data at startup | `false` |

## License

MIT License - See root LICENSE file.
