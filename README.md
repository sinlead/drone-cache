# drone-cache

A [Drone CI](https://drone.io/) plugin for caching data.

## Usable Settings

#### action
- required: true
- value: 'load' or 'save'

#### key
- required: true
- usage: a file to identify whether we could use existed cache
- value: a file/folder path

#### mount
- required: true
- usage: data should be chached
- value: a file/folder path

#### prefix
- required: suggested
- value: a string in format: `[A-Za-z][A-Za-z0-9_-]+`

## Example

```yaml
kind: pipeline

steps:
  # find cached node_modules by the file 'yarn.lock'
  - name: load-yarn-cache
    image: sinlead/drone-cache:1.0.0
    settings:
      action: load
      key: yarn.lock
      mount: node_modules
      prefix: yarn-modules-v1
    volumes:
      - name: cache
        path: /cache

  - name: yarn-install
    image: node:11-alpine
    commands:
      - yarn install

  # save installed node_modules to cache
  - name: save-yarn-cache
    image: sinlead/drone-cache:1.0.0
    settings:
      action: save
      key: yarn.lock
      mount: node_modules
      prefix: yarn-modules-v1
    volumes:
      - name: cache
        path: /cache

# the cache storage at your host
volumes:
  - name: cache
    host:
      path: /tmp/cache
```
