# Koha Docker Compose Setup

This repository contains a Docker Compose setup for hosting Koha with MariaDB, OpenSearch, and Memcached.

## Prerequisites

- Docker and Docker Compose
- A modern machine with at least 4GB of RAM (OpenSearch can be memory intensive)

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url> koha
    cd koha
    ```

2.  **Set up environment variables:**
    Copy the example environment file and update passwords as needed:
    ```bash
    cp .env.example .env
    ```

3.  **Build and start the services:**
    ```bash
    docker compose build
    docker compose up -d
    ```

4.  **Wait for initialization:**
    Koha will take a few moments to initialize the first time it starts. You can follow the logs with:
    ```bash
    docker compose logs -f koha
    ```

5.  **Access Koha:**
    -   **OPAC (Online Public Access Catalog):** [http://localhost](http://localhost)
    -   **Intranet (Staff Interface):** [http://localhost:8080](http://localhost:8080)

## Default Credentials

During the first run, Koha might need you to run the web installer.
To find the admin credentials, you can check the `koha-conf.xml` file inside the container:
```bash
docker exec -it koha-app koha-passwd library
```

## Services

-   **Koha:** The main application, based on `perl:slim-bookworm`.
-   **MariaDB:** Database backend.
-   **OpenSearch:** Search engine (alternative to Elasticsearch).
-   **Memcached:** For caching sessions and other data.
