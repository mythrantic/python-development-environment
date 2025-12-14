
# Python Project Environment Setup Template

it has docker-compose for development and deploying. it also configured with .devcontainer så you can go into the container and work on it from there.

# Requirements
- uv 


# a dev environment for python

```bash
# compose
docker compose up --build -d
docker compose down

# devcontainer
# open the folder in VSCode and it will prompt you to open in container

# image and run
docker build -t python-development-environment-image .
docker run --name python-development-environment-container -d -p 8000:8000 -v $(pwd):/workspace python-development-environment-image
```


