# Prot_lumerag — Local RAG with CrewAI, OpenSearch, and Ollama

[English](README.en.md) | [Português](README.md)

![Python](https://img.shields.io/badge/Python-3.11-blue?style=flat-square&logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![OpenSearch](https://img.shields.io/badge/OpenSearch-VectorDB-005EB8?style=flat-square&logo=opensearch&logoColor=white)

An experimental retrieval-augmented generation (RAG) application for uploading
documents, retrieving relevant passages, and asking questions about their
contents in Portuguese. Inference and embedding generation use local models
served by Ollama; OpenSearch stores the vectors, and a CrewAI agent prepares
answers from the retrieved passages.

> **Status:** Learning prototype; not production-ready. Vector retrieval may
> return irrelevant passages, and the model may make mistakes or state things
> that the sources do not support. Always check the passages shown with each
> answer.

## Why run a local LLM?

- **Privacy and data sovereignty:** Documents and prompts are processed by the
  local services in this Compose setup; inference is not sent to a commercial
  external API. This reduces exposure to third parties but does not replace
  access controls, host protection, network encryption, or governance.
- **No per-token provider charges:** Local inference does not incur per-request
  charges from a model provider. Hardware, power, storage, and operations still
  have costs.
- **An accessible AI learning lab:** Anyone with compatible hardware can
  experiment with RAG, prompts, local models, document retrieval, and agents
  without an API account or accumulating per-token charges. This makes it
  easier to repeat tests, compare approaches, and learn by doing. It does not
  mean the total cost is zero: hardware, power, and maintenance still matter.
- **Less reliance on external services:** After downloading the images and
  model, inference can run without depending on a cloud LLM endpoint. Initial
  setup and downloading images and models require network access.
- **Flexibility:** You can choose another Ollama-compatible model using the
  `OLLAMA_MODEL` variable, taking memory, performance, and the model's license
  terms into account.
- **Controlled experimentation:** Study RAG, document search, agent
  orchestration, and on-premises operations using test documents.

These are architectural goals, not a security certification. A local
deployment still needs authentication, authorization, updates, secrets
management, backups, and monitoring appropriate to its environment.

## Current features

- Gradio web interface for selecting and uploading one or more files.
- Text extraction from TXT, Markdown, PDF, DOC, DOCX, RTF, ODT, CSV, XLS, XLSX,
  PPTX, HTML, JSON, and XML files.
- Text chunking, local embedding generation through Ollama, and vector storage
  in OpenSearch.
- Semantic retrieval of the three closest passages as answer context. The
  passages are displayed below the answer so users can check the sources.
- A CrewAI agent that generates a concise answer using the local Ollama model,
  limited to one iteration and a maximum execution time.
- Panel login and per-account document isolation.
- Retrieved content is treated as untrusted data to reduce prompt-injection
  risk; structured output is validated with Pydantic.
- A button to cancel an in-progress query.

## Demo walkthrough

1. Start the services with Docker Compose and wait for the Ollama models to
   download on first run.
2. Open <http://localhost:7860>, select a text document, and upload it.
3. Ask a question that the document can answer.
4. Compare the answer with the retrieved passages displayed below it. Use this
   to discuss retrieval quality and the model's limitations.
5. To inspect the index, open OpenSearch Dashboards at
   <http://localhost:5601>. This is an administrative panel and should remain
   accessible only locally.

For a reproducible presentation, use demo documents you are authorized to
process and prepare questions whose answers are clearly present in them. Also
show an example where retrieval fails: evaluating limitations is part of the
demo, not a guarantee of accuracy.

### Interface — conceptual illustration

This AI-generated image is an illustrative mockup, not a screenshot of the
actual interface. Its layout and text may differ from the application. Text
embedded in the image is in Portuguese.

![Conceptual mockup of the RAG query interface](docs/images/interface-concept.jpg)

### Known limitations

- Vector retrieval depends on the quality of the embedding model and does not
  replace evaluating passage relevance.
- Generating embeddings adds ingestion and query latency; vector search is not
  necessarily faster than BM25, especially for small collections.
- The application applies the owner filter over a shared index; this does not
  replace separate OpenSearch users and permissions. Documents indexed before
  the owner metadata was added must be uploaded again by each account that
  needs access to them.
- The interface does not support document deletion or a complete update cycle.
- Quality depends on the extracted text, retrieved passages, and model. A
  plausible answer is not necessarily correct.
- Answers have a 512-token generation limit and may still be incomplete. Check
  that they have finished and compare them with the retrieved passages.
- OCR for scanned PDFs and images is not implemented.
- Prompt-injection defenses rely on prompt and output-format layers; they do not
  guarantee protection against every attempt to manipulate the model.

## Architecture

```text
Browser
   │ document upload / question
   ▼
Gradio + Python application
   ├── extracts text and splits it into chunks
   ├── generates embeddings ──────────► Ollama (nomic-embed-text)
   ├── stores and retrieves vectors ───► OpenSearch (k-NN / HNSW)
   └── question + retrieved passages ─► CrewAI ─► Ollama (llama3.2)
```

### Architecture — conceptual illustration

This AI-generated image is an illustration, not a faithful technical diagram:
it shows multiple agents and a different model name. The current implementation
uses one CrewAI agent and defaults to the `llama3.2` model. Text embedded in the
image is in Portuguese.

![Conceptual illustration of the local RAG architecture](docs/images/architecture-concept.jpg)

Docker Compose coordinates four services: the Gradio application, OpenSearch,
OpenSearch Dashboards, and Ollama. Vector search happens before answer
generation: the agent receives up to three retrieved passages, not the entire
document. OpenSearch data and models downloaded by Ollama are stored in Docker
volumes.

## Prerequisites

- Docker is required: Docker Engine with Docker Compose v2. On Windows/WSL, use
  Docker Desktop with WSL integration enabled.
- Network access on first startup to download images and models.
- An NVIDIA GPU with the NVIDIA Container Toolkit configured to use Compose
  without changes. The current configuration reserves one GPU for Ollama.
- Enough memory, storage, and VRAM for the selected model. Requirements vary
  with the model and its quantization.

> To run without an NVIDIA GPU, temporarily remove the
> `deploy.resources.reservations.devices` block from the `ollama` service in
> `docker-compose.yml` and set `OLLAMA_LLM_LIBRARY=cpu` in `.env`. Ollama will
> use the CPU, with lower performance.

### Tested environment

Tested on a laptop running Ubuntu on WSL 2, with 40 GB of RAM and an NVIDIA GTX
1650 (4 GB VRAM), using PDF ingestion and queries through the web chat. This
configuration does not represent minimum requirements or guarantee equivalent
performance on other hardware.

## Getting started

1. Clone the repository and change to its directory.
2. Create a local environment file from the example:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env`: replace `OPENSEARCH_INITIAL_ADMIN_PASSWORD` with a strong,
   unique password, and replace the demo password in `APP_USERS_JSON` with your
   own unique password(s) of at least 12 characters. Add one account per user,
   preserving the JSON format. Do not publish or share this file.
4. Start the services:

   ```bash
   docker compose up -d --build
   ```

5. Monitor startup:

   ```bash
   docker compose ps
   docker compose logs -f crewai-app ollama
   ```

6. Open <http://localhost:7860> and sign in with an account defined in
   `APP_USERS_JSON`. Each account can retrieve only the documents it uploaded.
   If needed, follow the `ollama` service logs to monitor the initial model
   download.

OpenSearch Dashboards is available at <http://localhost:5601> and requires
authentication. Sign in with the OpenSearch credentials defined in `.env` to
view indexes and documents or run tests in Dev Tools. The Dashboards and
OpenSearch ports are bound to the local machine only. On first startup, Compose
generates a local CA and an OpenSearch certificate; Dashboards and the
application validate the TLS connection using that CA. To load documents for
RAG, use the app interface: it extracts text, splits it into chunks, and
generates the embeddings required for vector search.

To stop the containers without deleting volumes:

```bash
docker compose down
```

Indexed data and models remain in Docker volumes. Removing them requires
explicitly deleting those volumes; doing so deletes the data.

## Configuration

Variables are set in `.env`. Available values are documented in `.env.example`,
including:

- `APP_USERS_JSON`: JSON object with panel usernames and passwords. Configure
  one account per person, use unique passwords of at least 12 characters, and
  keep `.env` private.
- `OPENSEARCH_INITIAL_ADMIN_PASSWORD`: initial password required by OpenSearch.
- `OPENSEARCH_USERNAME`: username used by the application.
- `OPENSEARCH_PORT` and `OPENSEARCH_DASHBOARDS_PORT`: host-published ports.
- `OLLAMA_PORT`: Ollama port, published on loopback by default.
- `OLLAMA_MODEL`: generative model used by the application.
- `OLLAMA_EMBEDDING_MODEL`: local model used to generate embeddings (default:
  `nomic-embed-text`, with 768 dimensions).
- `OLLAMA_LLM_LIBRARY`: Ollama inference backend (`cuda_v12` by default; use
  `cpu` when running without an NVIDIA GPU).
- `OPENSEARCH_JAVA_OPTS`: OpenSearch JVM initial and maximum memory.

### Choosing a larger model

The default `llama3.2` is a lighter option. If enough memory is available, you
can try a larger model, such as `gemma3:12b` (12 billion parameters). The
parameter count does not directly correspond to required memory: quantization,
context size, and other running services also affect RAM and VRAM usage. If
memory is insufficient, inference may become very slow or fail.

To try it, change `OLLAMA_MODEL` in `.env`:

```env
OLLAMA_MODEL=gemma3:12b
```

Then recreate the services to download the model and apply the configuration:

```bash
docker compose up -d --force-recreate ollama crewai-app
```

The initial download may be large and requires network access. Check the
`ollama` logs until the download finishes, and verify the selected model's
requirements, hardware compatibility, and license terms. If performance or
memory usage is unsuitable, restore `OLLAMA_MODEL=llama3.2`. A larger model does
not remove the application's token limit.

### Response language

By default, answers are generated in Portuguese. To switch to English, edit
`src/main.py` and, in the task description in `executar_rag`, replace
`Responda em português` with `Responda em inglês`. Then restart the service to
apply the change:

```bash
docker compose restart crewai-app
```

This changes the language of model-generated answers. The interface and status
messages remain in Portuguese.

The vector index is separate from the index used by the previous version.
After updating the application, upload documents again through the interface
to generate their embeddings; data from the old index remains in the Docker
volume.

## Risk mitigation for LLM and RAG applications

### AI security learning context

This prototype also applied concepts explored in practical TryHackMe labs,
including *Securing AI Systems*, *LLM Security*, *Prompt Injection*,
*Prompt Defence*, *Understanding AI Supply Chains*, *RAG Security Fundamentals*,
and *Data Poisoning in RAG Systems*. This learning informed controls such as
authentication, input validation, owner-based passage filtering, and treating
retrieved content as untrusted data. These controls are partial: they do not
detect or eliminate *data poisoning*, guarantee isolation in OpenSearch, or
make the project production-ready. The lab references describe the project's
learning context; they are not a security certification or independent
security validation.

- The project applies defensive controls at several layers:
  - **Gradio — interface:** individual account authentication, question
    validation, and upload size and count limits.
  - **CrewAI — orchestration:** structured output validated with Pydantic. The
    agent cannot delegate or use tools, so it does not perform external
    actions. If tools are added, critical actions should require explicit human
    approval.
  - **OpenSearch and embeddings — data:** documents are assigned their owner's
    identifier; search filters by that owner, and results are checked again
    before being added to the context. The application marks questions and
    documents as untrusted data and tells the model not to follow commands
    found in them.
- These controls reduce risk but do not eliminate prompt injection. Access
  filtering is applied by the application over a shared index; it does not
  replace independent OpenSearch ACLs. Check answers against retrieved
  passages.
- The Gradio interface is published only on `127.0.0.1:7860`. Authentication
  does not replace HTTPS: do not expose the service directly to a network or
  the Internet.
- Dashboards requires authentication, and its ports and the OpenSearch ports
  are bound to `127.0.0.1`. Do not change this binding to `0.0.0.0` or expose
  these services to a network or the Internet.
- Dashboards and the application validate the OpenSearch TLS certificate using
  a local CA persisted in a Docker volume. Do not disable this validation.
- Browser-to-Gradio communication uses HTTP in this configuration. For remote
  access, put the application behind an authenticated TLS solution and
  configure appropriate network rules.
- Uploaded documents are indexed in the persistent OpenSearch volume. Deleting
  the original file does not automatically remove its content from the index.
- `.env` contains secrets: keep it out of Git. If a credential is exposed,
  rotate it and consider whether it must also be invalidated in other services.
- Use only documents you are authorized to process and store.

## Technologies

- Python 3.11
- Gradio
- CrewAI
- LangChain / LangChain OpenAI (CrewAI 0.28.8 integration with Ollama's
  OpenAI-compatible local endpoint)
- OpenSearch and OpenSearch Dashboards
- Ollama

Direct dependency versions are pinned in `app/requirements.txt` to reduce
unexpected dependency-resolution changes. Pinning does not replace regular
upgrade and compatibility testing.

## Possible next steps

- Add document deletion and reindexing workflows.
- Integrate per-user OpenSearch controls instead of relying only on the
  application's authorization filter.
- Add tools only with explicit authorization and human approval before any
  external or irreversible action.
- Measure latency and quality on representative questions, also recording
  when answers are not supported by the sources.

## Context

Prototype developed for hands-on study of local AI architectures, vector
retrieval, and agent orchestration, combining on-premises infrastructure and
security concepts.
