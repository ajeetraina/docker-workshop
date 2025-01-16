## Using Docker Build Cloud

Method: 1 : Running it locally

```
docker buildx create --driver cloud dockerdevrel/demo-builder
docker buildx build --builder cloud-dockerdevrel-demo-builder .
```

<img width="1160" alt="image" src="https://github.com/user-attachments/assets/cefc21ac-d15b-444a-81f9-8bcfc46bfd4a" />


Method:2 =- Running it using GitHub Workflow

Open dockersamples/ repo and se the workflow.