
Compose File Watch is a feature introduced in Docker Compose version 2.22.0. It allows for automatic updates and previews of your running Compose services as you edit and save your code. This can enable a hands-off development workflow once Compose is running, as services automatically update themselves when you save your work.

```
services:
  web:
    build: .
    command: npm start
    develop:
      watch:   
        - actions: sync
          path: ./web
          target: /src/web
          ignore: 
            - node_modules/
        - action: rebuild
          path: package.json
```


The `watch` attribute in the Compose file defines a list of rules that control these automatic service updates based on local file changes. Each rule requires a path pattern and an action to take when a modification is detected. The action can be set to rebuild, sync, or sync+restart.

Here's a brief explanation of these actions:

- **rebuild**: Compose rebuilds the service image based on the build section and recreates the service with the updated image.
- **sync**: Compose keeps the existing service container(s) running, but synchronizes source files with container content according to the target attribute.
- **sync+restart**: Compose synchronizes source files with container content according to the target attribute, and then restarts the container.

You can also define a list of patterns for paths to be ignored using the ignore attribute. Any updated file that matches a pattern, or belongs to a folder that matches a pattern, won't trigger services to be re-created.
To use Compose Watch, you need to add the watch instructions to your compose.yaml file and then run your application with the docker compose watch command.

![file watch actions](images/file-watch-actions.png)




