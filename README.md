# Deploy Rails to AWS(without terraform)

### Dockerize your app
1. Add docker and docker-compose to your project(examples given in repo)
2. Run `docker-compose -f docker/development/docker-compose.yml up` to check if it's working on local machine

### Create IAM user in aws console
1. Sign up and sign in to AWS console
2. Go to IAM service, choose users tab, click `Add users`
3. Enter username, choose `Access key - Programmatic access`
4. From policies choose `AdministratorAccess` or any policies for your purposes
5. Review and create new user
6. !Important!, save credentials for this user
7. Create new password for this user via `Security credentials` tab on user's detail page
8. Copy SignIn link from `Console sign-in link:` on this page
9. Sign Out as root user and login to console using IAM user credentials

### Create ECR repository - place where we will be saving our app build
1. Go to ECR (Elastic Container Registry), click `Create Repository`
2. Enter repo name and click `Create`

### Prepare security groups for load balancer and our app
1. Go to EC2, find `Scurity groups`
2. Click `Create security group`
3. Enter name and description (sg-load-balancer)
4. Add inbound rule `Type -> HTTP`, `Source -> Anywhere ipv4`
5. Create
6. Create another group for app
7. Enter name and description (sg-rails)
8. Add inbound rules:
   - `type -> SSH`, `source -> anywhwre ipv4`
   - `type -> all TCP`, `source -> <security group that created for load balancer>`
9.Create

### Create SSH key-pair
1. Go to EC2, find `key pairs`
2. Create new key-pair (fill-in its name and seve .pem file on your local machine)

### Create load balancer
1. Go to EC2, find `load balancers`, click `Create new load balancer`
2. Choose `Application load balancer` type, click next
3. Fill in its name
4. `Scheme -> Internet-facing`
5. `IP address type -> IPv4`
6. In `Network mapping` choose at least 2 subnets, don't forget what subnets you've chosen, you will need it later
7. In `Security Groups` select secutiry goup for load balancer that have beed created earlier
8. `Listeners and routing` -> create new target group:
    - `Target type -> Instances`
    - Fill in its name
    - `Protocol -> HTTP`, `PORT -> 80`
    - For Health checks, enter route name for health checking(Just add route that returns 200 status in your app)
    - Create
9. Choose just created target group
10. `Create load balancer`

### Push app build to ecr
1. Run in root of your project `docker build . -f docker/<env_name>/Dockerfile `
2. Copy just built image id from `docker images` output
3. Run `docker tag <image_id> <ecr_link>:<tag>`, ecr_link - copy link from repository that created in ECR, tag - for example, `staging`
4. Run `aws configure` and fill in access key and secret key from saved IAM credentails (This step need to be done only one time)
5. Run `aws ecr get-login --no-include-email --region=<your_region>` and copy-past output and run this command
6. Run `docker push <ecr_link>:<tag>`
7. DONE

### Create task definition for rails app, sidekiq, redis, db(postgres)
1. Go to ecs, click `Task Definitions`
2. Create new task definition
3. Enter name
4. `type -> ec2`
5. Scroll down and add volumes:
      1. `Name -> redis
          Volume type -> Docker
          Driver -> local
          Scope -> Shared
          Auto-provisioning enabled -> true`
      2.  `Name -> postgres
          Volume type -> Docker
          Driver -> local
          Scope -> Shared
          Auto-provisioning enabled -> true`
      3. `Name -> public Volume type -> Bind Mount`
6. Enter task memory and task cpu (for example 512x512)

Next we need to add containers (rails-server, db-host, redis-db, sidekiq)

redis-db:
1. `Image -> image name from docker-hub`
2. Ports `6379:6379`
3. Healthcheck `command -> CMD-SHELL,redis-cli -h localhost ping, interval -> 30, timeout -> 5, retries -> 3`
4. Storage and logging `mount points -> source_volume -> redis, cont_path -> /data`
5. Log configuration `true`
6. Create

db-host:
1. `Image -> image name from docker hub`
2. Ports `5432:5432`
3. Healthcheck `command -> CMD-SHELL,pg_isready -U postgres, interval -> 30, timeout -> 5, retries -> 3`
4. Env variables such as `POSTGRES_USER -> postgres, POSTGRES_PASSWORD -> postgres`
5. Storage and logging `mount points -> source_volume -> postgres, cont_path -> /var/lib/postgresql/data`
6. Log configuration `true`
7. Create

rails-server:
1. `Image -> <ecr_link>:<tag>`
2. Ports `3000:3000`
3. Healthcheck `command -> CMD-SHELL,curl -f http://localhost:3000/health_check || exit 1, interval -> 30, timeout -> 5, retries -> 3`
4. Environment `entry point -> docker/staging/entrypoint.sh, command -> bundle,exec,puma,-C,config/puma.rb,-p,3000`
5. Env variables (all env variables we need like RAILS_ENV, AWS KEYS), exmaple: `DB_HOST -> db-host(we created earlier), REDIS_URL -> redis://redis-db:6379/1 (we created earlier)`
6. Startup deps ordering `db-host -> HEALTHY, redis-db -> HEALTHY`
7. Network settings `links -> db-host,redis-db (we connect to redis and db from our app)`
8. Storage and logging `mount points -> source_volume -> public, cont_path -> /home/www/<app_name>/public (path to public folder of our app) check Dockerfile`
9. Log configuration `true`
10. Create

sidekiq:
1. `Image -> <ecr_link>:<tag>`
2. Ports `skip`
3. Healthcheck `command -> CMD-SHELL,ps ax | grep -v grep | grep sidekiq || exit 1, interval -> 30, timeout -> 5, retries -> 3`
4. Environment `command -> bundle,exec,sidekiq,-C,config/sidekiq.yml`
5. Env variables `copy from rails-server`
6. Startup deps ordering `db-host -> HEALTHY, redis-db -> HEALTHY, rails-server -> HEALTHY`
7. Network settings `links -> db-host,redis-db (we connect to redis and db from our app)`
8. Storage and logging `mount points -> source_volume -> public, cont_path -> /home/www/<app_name>/public (path to public folder of our app) check Dockerfile`
9. Log configuration `true`
10. Create

