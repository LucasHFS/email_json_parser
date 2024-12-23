# Implementing The Real Challenge

---

## Requirements

- Ruby (>= 3.3.5 recommended)
- Bundler (>= 2.5.16)
- Git (for cloning the repository)

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/lucashfs/email_json_parser.git

cd email_json_parser
```

### 2. Install Dependencies
```bash
gem install bundler

bundle install
```

### 3. Run the app
```bash
ruby app.rb
```

## Example Requests

### POST /parse_email
#### Using email url source
```bash
curl -X POST "http://127.0.0.1:4567/parse_email" \
-H "Content-Type: application/json" \
-d '{ "email_source": "https://raw.githubusercontent.com/LucasHFS/email_json_parser/refs/heads/main/storage/email_with_json_attachment.eml" }'
```

#### Using file path source

```bash
curl -X POST "http://127.0.0.1:4567/parse_email" \
-H "Content-Type: application/json" \
-d '{ "email_source": "storage/email_with_json_link.eml" }'
```

