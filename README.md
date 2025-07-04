# DevOps

# TP1

## 1-1 For which reason is it better to run the container with a flag `-e` to give the environment variables rather than put them directly in the Dockerfile?  
It is better to use the `-e` flag when running a container to pass environment variables—like database usernames and passwords—rather than hardcoding them directly in the Dockerfile, because it improves **security** and **flexibility**. Hardcoding secrets in a Dockerfile exposes sensitive information to anyone who accesses the file or image, especially if it's version-controlled (e.g., on GitHub).

Using `-e` keeps your Docker images clean and reusable across different environments (development, staging, production) without needing to rebuild them. It also avoids leaving secrets in the image history, making your setup safer and easier to manage.

## 1-2 Why do we need a volume to be attached to our Postgres container?  
Postgres stores its data in `/var/lib/postgresql/data` inside the container’s writable layer, which is ephemeral. Attaching a volume maps that directory to a path on the host (or a named volume), so that:
- **Data persists** even if the container is removed or recreated.  
- **Backups** and host-level tools can directly access the files.  
- **Performance** can be improved by using optimized host storage.  
- **Isolation** of data from container lifecycle makes your database durable and production-ready.

## 1-3 Document your database container essentials: commands and Dockerfile.

### Files
#### Dockerfile  
```dockerfile
FROM postgres:17.2-alpine

# copy all .sql scripts into the init folder
COPY initdb/*.sql /docker-entrypoint-initdb.d/
```

#### Environment file (.env)
```.env
POSTGRES_DB=db
POSTGRES_USER=usr
POSTGRES_PASSWORD=pwd
```
### Commands
#### Build the image
```image
docker build -t lpontes/tp1 .
```

#### Create the network
```network
docker network create app-network
```

#### Run the database container
```container
docker run -d \ --name devopstp1 \ --network app-network \ --env-file .env \ -v "$(pwd)/data:/var/lib/postgresql/data" \ lpontes/tp1
```

#### Verify it’s running
```run
docker ps
docker logs devopstp1
```

#### Run Adminer
```adminer
docker run -d \ --name adminer \ --network app-network \ -p 8090:8080 \ adminer
```
#### Access Adminer
Open your browser at http://localhost:8090 and enter:
- System: PostgreSQL
- Server: devopstp1
- Username: usr
- Password: pwd
- Database: db

## 1-4 Why do we need a multistage build? And explain each step of this Dockerfile

### Why use a multistage build?

A multistage build is especially useful for **Java applications**, because Java code must first be **compiled** (with tools like Maven or Gradle) before it can be executed by the **Java runtime**.

Using a multistage build allows us to:
- Compile the application in one stage using a **full JDK** and build tools (like Maven).
- Copy only the final `.jar` to a new stage that uses a **lightweight JRE**, removing unnecessary files and build dependencies.
- Improve **security** by excluding tools and source code from the final image.
- Reduce the final image **size**, making deployments faster and more efficient.
- Keep the Dockerfile **modular**, clean, and environment-specific

---

### Dockerfile Explained

```dockerfile
# --- Build stage ---
FROM eclipse-temurin:21-jdk-alpine AS myapp-build
ENV MYAPP_HOME=/opt/myapp
WORKDIR $MYAPP_HOME

RUN apk add --no-cache maven

COPY pom.xml .
COPY src ./src
RUN mvn package -DskipTests
```
#### Build stage:
- **FROM eclipse-temurin:21-jdk-alpine AS myapp-build**: Uses a Java 21 JDK Alpine image with a label for this build stage.
- **ENV** and **WORKDIR**: Define and switch to the working directory.
- **RUN apk add --no-cache maven**: Installs Maven (needed only for build).
- **COPY pom.xml .** and **COPY src ./src**: Adds project files to the container.
- **RUN mvn package -DskipTests**: Builds the Spring Boot project and creates a .jar file.

```dockerfile
# --- Run stage ---
FROM eclipse-temurin:21-jre-alpine
ENV MYAPP_HOME=/opt/myapp
WORKDIR $MYAPP_HOME

COPY --from=myapp-build $MYAPP_HOME/target/*.jar $MYAPP_HOME/myapp.jar

ENTRYPOINT ["java", "-jar", "myapp.jar"]
```

#### Run stage:
- **FROM eclipse-temurin:21-jre-alpine**: Uses a smaller image with only the Java runtime (JRE).
- **WORKDIR** and **ENV**: Set up the same working directory as before.
- **COPY --from=myapp-build**: Copies only the final .jar from the build stage — not the source or tools.
- **ENTRYPOINT**: Defines the command to run the application when the container starts.

The result: a lightweight, production-ready Docker image that contains only what's necessary to run your Spring Boot app.

## 1-5 Why do we need a reverse proxy?

A reverse proxy sits in front of one or more backend servers and forwards client requests on their behalf. By centralizing incoming traffic, it provides **load balancing**, distributing requests across multiple instances to improve performance and availability. It also handles **SSL termination**, offloading the computational overhead of encryption/decryption from the application servers.

Beyond performance, a reverse proxy enhances **security** and **flexibility**. It can enforce firewall rules, rate-limit traffic, and hide the internal network topology. It also enables **URL routing** and **caching** of static assets, reducing latency and offloading repetitive work from the backends—all without changing the application code.

## 1-6 Why is docker-compose so important?

Docker Compose lets you define and run **multi-container applications** with a single declarative YAML file. Instead of typing a dozen `docker run` commands to wire together your database, backend, and reverse-proxy, you simply run `docker-compose up`. Compose handles network creation, volume mounts, build order, restart policies, and inter-service dependencies automatically. This greatly improves **developer productivity**, ensures **consistency** across environments, and makes it easy to share the exact same setup with teammates or in CI/CD pipelines.

---

## 1-7 Document docker-compose’s most important commands

- `docker-compose up [--build]`  
  Build images (if needed) and start all services defined in `docker-compose.yml` in the correct order.

- `docker-compose down`  
  Stop and remove all containers, networks, and (optional) named volumes created by `up`.

- `docker-compose build`  
  Build or rebuild service images without starting containers.

- `docker-compose ps`  
  List the status of all services (containers) in the current Compose project.

- `docker-compose logs [service]`  
  View aggregated logs for all services, or for a specific service if you pass its name.

- `docker-compose exec <service> <command>`  
  Run an interactive command inside a running container (e.g. `docker-compose exec backend sh`).

- `docker-compose restart [service]`  
  Restart all or selected services.

- `docker-compose config`  
  Validate and view the final interpolated configuration after variable substitution.

- `docker-compose pull`  
  Pull updated images for all services from registries, without building locally.

---

## 1-8 Document your docker-compose file

```yaml
services:
  database:
    build: ./Database
    env_file:
      - .env
    volumes:
      - ./Database/data:/var/lib/postgresql/data
    networks:
      - db-network
    restart: on-failure:3

  backend:
    build: ./simpleapi
    env_file:
      - .env
    depends_on:
      - database
    networks:
      - db-network
      - front-network
    restart: on-failure:3

  httpd:
    build:
      context: ./http-server
      dockerfile: Dockerfile
    env_file:
      - .env
    depends_on:
      - backend
    ports:
      - "80:80"
    networks:
      - front-network
    restart: on-failure:3

networks:
  db-network:
    driver: bridge
  front-network:
    driver: bridge

volumes:
  db-data:
    driver: local
```
### Services

#### database  
- **Build context**: `./Database`, uses `Database/Dockerfile` (copies init scripts into Postgres image).  
- **env_file**: loads `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` from root `.env`.  
- **Volumes**: mounts `./Database/data` on the host into `/var/lib/postgresql/data` inside the container for durable storage.  
- **Network**: attached only to `db-network`, isolating it from external access.  
- **Restart policy**: `on-failure:3` will retry up to 3 times on an unexpected crash; beyond that it stops to avoid endless loops if misconfigured.  

#### backend  
- **Build context**: `./simpleapi`, uses `simpleapi/Dockerfile` (multi-stage Java build).  
- **env_file**: loads DB credentials and host/port from `.env`.  
- **depends_on**:  
  - ensures `database` starts before the API attempts a connection.  
- **Networks**:  
  - on `db-network` to talk to Postgres,  
  - on `front-network` to receive requests from the reverse proxy.  
- **Restart policy**: `on-failure:3` retries up to 3 times on crashes or startup failures, then stops so you can inspect logs if a persistent bug exists.  

#### httpd  
- **Build context**: `./http-server`, uses `http-server/Dockerfile`—templates `httpd.conf`, installs `envsubst`, serves `index.html` and proxies to the backend.  
- **env_file**: loads `CONTAINER_PROXY` to target the correct backend container name.  
- **depends_on**: waits for `backend` before starting.  
- **Ports**:  
  - exposes host port `80` and maps it to container port `80`—this is the only service accessible externally.  
- **Network**: attached only to `front-network`, so it can forward traffic to `backend` but is isolated from direct database access.  
- **Restart policy**: `on-failure:3` ensures transient proxy errors get retried, but prevents endless restart loops on misconfiguration.  

---

### Networks

#### db-network  
- Bridge network dedicated to **database ↔ backend** traffic.  
- Keeps Postgres inaccessible from the outside world.  

#### front-network  
- Bridge network dedicated to **backend ↔ reverse-proxy** traffic.  
- Only the `httpd` service exposes a port to the host.  

---

### Volumes

#### db-data  
- Named volume (driver: `local`) for Postgres data, ensuring durability even if you remove the container.  

## 1-9 Document your publication commands and published images in Docker Hub

```bash
# Step 1: Authenticate with Docker Hub
docker login

# Step 2: Tag the local image with the appropriate Docker Hub repository and version
docker tag devops-database luthean3/devops-database:1.0
docker tag devops-backend luthean3/devops-backend:1.0
docker tag devops-httpd luthean3/devops-httpd:1.0

# Step 3: Push the tagged images to Docker Hub
docker push luthean3/devops-database:1.0
docker push luthean3/devops-backend:1.0
docker push luthean3/devops-httpd:1.0
```

Once pushed, you can view your images at:  
https://hub.docker.com/repository/docker/luthean3/devops-database  
https://hub.docker.com/repository/docker/luthean3/devops-backend  
https://hub.docker.com/repository/docker/luthean3/devops-httpd  

---

## 1-10 Why do we put our images into an online repo?

- **Team collaboration**: Other developers can pull and run the same images on their machines without rebuilding them from scratch.
- **CI/CD & Deployment**: Automated pipelines and production servers can pull images directly from the registry.
- **Portability**: The image is no longer tied to your local environment; it can run anywhere Docker is installed.
- **Versioning & traceability**: Tags like `:1.0`, `:latest`, or `:dev` help manage updates and rollbacks.
- **Centralized source of truth**: Docker Hub (or private registries) serve as the canonical source for your container artifacts.

> Companies often self-host image registries for security, access control, and integration with internal tooling.

# TP2

## 2-1 What are testcontainers?

**Testcontainers** is a Java library that provides lightweight, throwaway instances of common databases, Selenium web browsers, or anything else that can run in a Docker container. It is mainly used for **integration testing** to spin up real dependencies (like PostgreSQL, MySQL, Kafka, Redis, etc.) inside Docker containers during the test lifecycle.

### Key points about Testcontainers:
- Allows running real instances of services inside Docker containers for tests.
- Ensures that your integration tests run against the same environment your application will use in production.
- Containers are automatically started before tests and stopped after, ensuring clean state.
- Simplifies test setup without requiring manual installation or dedicated test environments.
- Works well with JUnit and other testing frameworks.
- Improves test reliability and consistency by isolating dependencies.

## 2-2 For what purpose do we need to use secured variables?

We use **secured variables** (also known as **secrets**) in CI/CD pipelines like GitHub Actions to:

- **Protect sensitive credentials** such as Docker Hub usernames, passwords, API tokens, and SSH keys from being exposed in the codebase.
- **Prevent accidental leakage** of secrets into logs or public repositories.
- **Allow secure access** to external services (e.g., Docker Hub, AWS, databases) during automated workflows without hardcoding them in your YAML files.
- **Enable safe collaboration** in public or shared repositories by ensuring contributors cannot access or modify secrets.

> Good practice: Always store secrets in GitHub under `Settings > Secrets and variables > Actions` and reference them using `${{ secrets.NAME }}` in your workflow.

## 2-3 Why did we put `needs: test-backend` on this job?

We use `needs: test-backend` to **ensure that the `build-and-push-docker-image` job only runs if the tests pass**. This is a good CI/CD practice because:

- It prevents broken code from being packaged and pushed to Docker Hub.
- It guarantees that only validated, working code reaches the delivery stage.
- It helps maintain the integrity of the images stored in the registry.

> If you remove the `needs:` dependency, the build-and-push job may run **in parallel** with tests, or even if the tests **fail**, which would break the idea of reliable Continuous Delivery.

## 2-4 For what purpose do we need to push Docker images?

We push Docker images to a remote registry (like Docker Hub) to make them:

- **Accessible from anywhere**: CI/CD pipelines, teammates, and deployment servers can pull the same image.
- **Reproducible**: Ensures that everyone runs the exact same environment, avoiding "it works on my machine" issues.
- **Deployable**: Enables automatic deployment to production or staging environments using container orchestration tools like Kubernetes or Docker Compose.
- **Version-controlled**: Each pushed image can be tagged (e.g., `1.0`, `latest`, `staging`) for easy tracking and rollback if needed.
- **Scalable**: Supports modern deployment workflows with cloud providers and microservices architectures.

> In short, pushing Docker images is essential for automation, sharing, deployment, and consistency in modern DevOps workflows.

## 3-1 Document your inventory and base commands

We use an Ansible inventory to define our target server(s) and associated connection parameters. In this project, the inventory is defined in `ansible/inventories/setup.yml`:

```yaml
all:
  vars:
    ansible_user: admin
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
  children:
    prod:
      hosts:
        lucas.pontes.takima.cloud:
```

This YAML file sets:
- the SSH user as `admin`,
- the private key path for authentication,
- and a group called `prod` that includes the remote host `lucas.pontes.takima.cloud`.

### Base Ansible Commands
#### Test SSH connection:
```ssh connection
ansible all -i ansible/inventories/setup.yml -m ping
```

#### Get system facts (OS distribution):
```OS
ansible all -i ansible/inventories/setup.yml -m setup -a "filter=ansible_distribution*"
```

#### Remove Apache2 if installed:
```Apach2
ansible all -i ansible/inventories/setup.yml -m apt -a "name=apache2 state=absent" --become
```

This ensures the Apache2 package is removed. The --become flag allows privilege escalation (like sudo).

  > These commands describe the desired state of your infrastructure. Ansible enforces that state, making server configuration automated, reproducible, and reliable.

  ## 3-2 Document your playbook

### First playbook

This is a minimal playbook to test connectivity with all hosts defined in the inventory:

```yaml
- hosts: all
  gather_facts: false
  become: true

  tasks:
   - name: Test connection
     ping:
```

- **hosts: all** — targets all hosts from the inventory.
- **gather_facts**: false — disables fact gathering for faster execution.
- **become: true** — escalates privileges (sudo) for tasks.
- The single task **ping** checks if Ansible can reach the host successfully.

Run it with:
```command
ansible-playbook -i inventories/setup.yml playbook.yml
```

### Advanced playbook to install Docker
This playbook installs Docker on Debian-based servers with these steps:
```yml
- hosts: all
  gather_facts: true
  become: true

  tasks:
   - name: Install required packages
     apt:
       name:
         - apt-transport-https
         - ca-certificates
         - curl
         - gnupg
         - lsb-release
         - python3-venv
       state: latest
       update_cache: yes

   - name: Add Docker GPG key
     apt_key:
       url: https://download.docker.com/linux/debian/gpg
       state: present

   - name: Add Docker APT repository
     apt_repository:
       repo: "deb [arch=amd64] https://download.docker.com/linux/debian {{ ansible_facts['distribution_release'] }} stable"
       state: present
       update_cache: yes

   - name: Install Docker
     apt:
       name: docker-ce
       state: present

   - name: Install Python3 and pip3
     apt:
       name:
         - python3
         - python3-pip
       state: present

   - name: Create a virtual environment for Docker SDK
     command: python3 -m venv /opt/docker_venv
     args:
       creates: /opt/docker_venv

   - name: Install Docker SDK for Python in virtual environment
     command: /opt/docker_venv/bin/pip install docker

   - name: Make sure Docker is running
     service:
       name: docker
       state: started
     tags: docker
```

- **Install required system packages** for Docker and Python virtual environment.
- **Add Docker’s official GPG key** to verify packages.
- **Add Docker APT repository** for stable Docker version.
- **Install Docker CE** package.
- **Install Python3 and pip3** to manage Python packages. 
- **Create a Python virtual environment** for Docker SDK.
- **Install Docker Python SDK** inside the virtual environment. 
- **Ensure Docker service is started** and running.

## 3-3 Document your docker_container tasks configuration
In this project, we use the Ansible `docker_container` module to automate the deployment and management of our application containers (database, backend, and httpd proxy) on the target server. Each service is defined in its own Ansible role, and the configuration ensures that containers are started with the correct images, environment variables, networks, and volumes.

Example: Lauching the backend API container
```Task
- name: Launch backend API container
  docker_container:
    name: backend
    image: luthean3/devops-simple-api:latest
    pull: yes
    env_file: /home/admin/project/.env
    networks:
      - name: db-network
      - name: front-network
    restart_policy: on-failure
    restart_retries: 3
```

### Key configuration points:
- `name`: The container name (e.g., `backend`).
- `image`: The Docker image to use (pulled from Docker Hub or a registry).
- `pull`: Ensures the latest image is pulled before starting.
- `env_file`: Loads environment variables from a file (here, `/home/admin/project/.env`).
- `networks`: Attaches the container to one or more Docker networks for service communication.
- `restart_policy`: Defines how Docker restarts the container on failure.
- `restart_retries`: Limits the number of restart attempts.

Example: Launching the database container
```Task
- name: Launch PostgreSQL container from Docker Hub image
  docker_container:
    name: database
    image: luthean3/devops-database:latest
    pull: yes
    env_file: /home/admin/project/.env
    volumes:
      - /home/admin/project/database/data:/var/lib/postgresql/data
    networks:
      - name: db-network
    restart_policy: unless-stopped
```
- `volumes`: Mounts a host directory for persistent database storage.

Example: Launching the httpd proxy container
```Task
- name: Launch HTTPD proxy container
  docker_container:
    name: httpd
    image: luthean3/devops-httpd:latest
    pull: yes
    env_file: /home/admin/project/.env
    networks:
      - name: front-network
    ports:
      - "80:80"
    restart_policy: no
```
- `ports`: Exposes container ports to the host (here, HTTP on port 80).

### Summary:
Each docker_container task ensures the right image, environment, and networking for each service, closely mirroring the `docker-compose.yml` setup but managed declaratively and idempotently with Ansible. This approach allows for automated, repeatable deployments on any compatible server.
