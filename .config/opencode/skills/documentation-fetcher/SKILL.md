---
name: documentation-fetcher
description: Fetch current documentation from the web using llms.txt and structured sources
license: MIT
compatibility: opencode
metadata:
  category: documentation
  tools: webfetch
---

## What I do

I help you fetch current documentation for tools, languages, libraries, and technologies from the web, supplementing knowledge cutoffs with the latest information. I prioritize efficiency by using the `llms.txt` standard and filtering out irrelevant content.

**Core capabilities:**
1. **llms.txt discovery**: Attempt to fetch structured documentation links from `https://<domain>/llms.txt`
2. **Relevance filtering**: Extract only URLs and sections directly related to your query
3. **Content fetching**: Retrieve documentation pages and extract relevant information
4. **Discard irrelevant info**: Ignore marketing, blog posts, and unrelated content unless specifically requested

**Priority system:**
- **First**: Try `llms.txt` from the target domain (most structured)
- **Second**: Try common documentation URLs (e.g., `/docs`, `/documentation`)
- **Third**: Rely on knowledge cutoff with appropriate disclaimer

**Security constraints:**
- Read-only operations (fetching documentation)
- No write operations required
- Only webfetch tool usage

## When to use me

Use this skill when you need current information about:

- **New features**: "How do I use the new `wait()` function in pytest 8?"
- **API changes**: "What's the new signature for `fetch()` in Node.js 20?"
- **Library updates**: "How do I configure the latest version of FastAPI?"
- **Tool documentation**: "What are the new flags in Docker CLI?"

**Before using me**, make sure:
1. You have a specific question about a tool, library, or technology
2. The target has an online presence (website, GitHub repo, etc.)
3. You want current information (not relying solely on knowledge cutoff)

## How to use me

### Basic documentation fetch

Ask about any tool, library, or technology:

```
What is the new `wait()` function in pytest version 8?
```

```
How do I use the latest features in FastAPI?
```

### Specific API reference

Ask for specific API details:

```
What's the new signature for `fetch()` in Node.js 20?
```

```
How do I configure the new options in Docker CLI?
```

### Version-specific questions

Specify the version you're interested in:

```
What's new in Django 5.0?
```

```
How do I use the new ORM features in SQLAlchemy 2.0?
```

## How I work

### Priority system

1. **llms.txt discovery**:
   - Try `https://<target>/llms.txt`
   - Try `https://www.<target>/llms.txt`
   - Parse structured links from the file

2. **Relevance filtering**:
   - Extract URLs from sections like "Documentation", "API Reference", "Changelog"
   - Score URLs based on relevance to your query
   - Prioritize documentation over blog posts and marketing

3. **Content fetching**:
   - Fetch the most relevant documentation pages
   - Extract specific information matching your query
   - Discard irrelevant sections

4. **Fallback strategy**:
   - If `llms.txt` is not found, try standard documentation URLs
   - If no documentation found, rely on knowledge cutoff with disclaimer

### Relevance scoring

I calculate relevance based on:
- **Section type**: "Documentation", "API Reference" score higher than "Blog"
- **Link text**: Matches containing your query keywords
- **URL path**: URLs containing your query terms

### Discard rules

I automatically discard:
- Blog posts (unless you ask for blog content)
- Press releases and marketing materials
- General website pages not containing technical documentation
- Irrelevant sections from documentation pages

## Available operations

### Read operations (automatic)

**Fetch llms.txt from domain**:
```bash
webfetch https://<domain>/llms.txt format=text
```

**Fetch documentation page**:
```bash
webfetch <url> format=markdown
```

### Processing steps
1. **Parse llms.txt**: Extract structured documentation links
2. **Filter URLs**: Keep only relevant links based on query
3. **Fetch pages**: Retrieve documentation content
4. **Extract info**: Find specific information matching query
5. **Filter content**: Discard irrelevant sections

## Example workflow

**User query**: "How do I use the new `wait()` function in pytest version 8?"

**My process**:
1. Identify target: `pytest.org`
2. Try `https://pytest.org/llms.txt`
3. If found, parse for relevant URLs (API reference, changelog)
4. Fetch the most relevant page
5. Extract `wait()` function documentation
6. Return only the relevant information

**Result**:
```
The `wait()` function in pytest 8 is used for...

Example usage:
```python
def test_example():
    wait(timeout=5)
```

[Source: pytest.org/docs/...]
```

## Tips

- **Be specific**: The more specific your query, the better the results
- **Include version**: Specify versions when asking about updates
- **Target domain**: I'll try to infer the domain from your query
- **Relevance filtering**: I'll automatically discard irrelevant content
- **Fallback behavior**: If no documentation found, I'll use knowledge cutoff with disclaimer
- **llms.txt priority**: I always try structured documentation first
- **Multiple attempts**: I'll try different URL patterns before giving up
