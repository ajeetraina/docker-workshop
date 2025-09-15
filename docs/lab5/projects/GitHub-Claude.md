

Let’s see how to use GitHub MCP Server using Claude Desktop in the following steps:

## Step 1: Create a GitHub Personal Access Token (PAT)


- Go to GitHub.com and sign in to your account
- Click your profile picture in the top-right corner
- Select "Settings"
- Scroll down to "Developer settings" in the left sidebar
- Click on "Personal access tokens" → "Tokens (classic)"
- Click "Generate new token" → "Generate new token (classic)"
- Give your token a descriptive name like "Docker MCP GitHub Access"
- Select the following scopes (permissions):
 - repo (Full control of private repositories)
 - workflow (if you need workflow actions)
 - read:org (if you need organization access)
- Click "Generate token"

## Step 2: Configure the GitHub MCP Server in Docker

- Open Docker Desktop
- Navigate to the MCP Server
- Find the GitHub tool (official) card and click on it to expand details.

![githubrefernece](./images/github-reference.png)

In your terminal, set up the GitHub token as a secret:

```
docker mcp secret set GITHUB.PERSONAL_ACCESS_TOKEN=github_pat_YOUR_TOKEN_HERE
```

For example:

```
docker mcp secret set GITHUB.PERSONAL_ACCESS_TOKEN=github_pat_11AACMRCAXXXXXXxEp_QRZW43Wo1k6KYWwDXXXXXXXXGPXLZ7EGEnse82YM
Info: No policy specified, using default policy
```


