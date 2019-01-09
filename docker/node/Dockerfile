FROM node:carbon

# Create app directory
WORKDIR /app

# Install app dependencies
#COPY package*.json ./
#RUN npm install

# Copy app source code
COPY . /app

# Copy existing application directory permissions
#COPY --chown=node:node . /app

# Change current user to node
#USER node

VOLUME /app/node_modules

#Expose port and start application
#EXPOSE 8080
#CMD [ "npm", "start" ]
