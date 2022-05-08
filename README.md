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

