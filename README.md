# RPA case example

A case example for developing RPA solutions.

The case process involves reading 'messages' from local files, posting message content to a REST API, making decisions based on the API call results, using a web application to store message contents, storing data into Excel spreadsheets, and logging any result or error from the process.

The case example consis of a dockerized environment that has the following containers:

* Message checker REST API
* Database server for storing message id and hash data
* Web app for inserting data into the database

## Running the environment

Running the environment will require `Docker`. There is a Makefile that handles calling Docker commands so to run that, `GNU Make` is also required.

Makefile instructions:

```
Help:           'make'
Build images:   'make docker/build'
Run env:        'make env/run'
Stop env:       'make env/stop'
New message:    'make message'
```

The convenience target `make message` will use the API service to generate a new message in the messages folder that has the ID of the current timestamp. This target will use `curl` to call the API. To create a message with a specific id, use `make message ID=<int>`.

Running the environment without Make:

```
Build images:   'docker-compose build'
Run env:        'docker-compose up -d'
Stop env:       'docker-compose down'
```

## Business process

### TLDR;

1. Read files from local ./messages folder, parse one message per line. Remove files when read.
2. Post JSON with message id and hash as JSON `{"id":<id>,"hash":"<hash>"}` to `localhost:1881/checkMessage`.
3. API response will be the following: 200, 400, or 500. When succesful, interpret payload JSON:
  1. confirm - insert content into an Excel spreadsheet, then insert data into web app
  2. accept - insert data directly into web app
  3. combine - wait for another message with specified id and combine both into web app
4. The web app is located at `localhost:1880/ui` and is self-explanatory to use. Excel can be stored locally.
5. A log must show how many different results have been received and how many errors have occurred.
6. An audit trail of each transaction has to be preserved.

### Long version

There is a folder labelled 'messages' that receives message files from an external system. These message files contain one or more individual messages, each on its own new line. A message consists of an integer id and the SHA256 hash of that id in the following format:

```
<id>:"<hash>"
<id>:"<hash>"
<id>:"<hash>"
```

When messages arrive, a person will read the content of the messages folder from time to time and process new files. The files are removed from the folder when they are picked. The person will send the content of each message to special message checker API as an HTTP POST with JSON content as follows:

```
curl -H "Content-Type: application/json" -X POST -d '{"id":123,"hash":"a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"}' localhost:1881/checkMessage
```

As can be seen from the curl example, the API is located on:

```
localhost:1881/checkMessage
```

This service will return the following status codes:

```
200: success
400: invalid request
500: invalid content
```

When returning success, the response will also contain a JSON payload.

```
{'response':'confirm'}              - message will require manual confirmation.
{'response':'accept'}               - message is automatically accepted.
{'response':'combine', 'id':<int>}  - message will require combining with another message.
```

If the message requires manual confirmation, the person will add the id and hash of the message to an Excel spreadsheet. Then the message content is inserted into a web application that can be found at:

```
localhost:1880/ui
```

There the person simply inserts the id and hash into the text fields and presses the submit button. If the message can be automatically accepted, the content of the message will be inserted directly into this web application without adding the information into Excel.

In the case of a combination request, the user will store the message information for later until a message is received that has the same id specified in the combine response. Then the message ids and hash strings are simply appended together and inserted into the web app form. The second message will also need to be checked for validity on the message checker API but any other result than invalid request/content responses can be ignored.

### Error handling and logging

In the case of an error from the message checker API, the user will make a note of the return code and the message content into an error log. The organization will also want to know the following things on reqular basis:

* The number of errors
* The number of confirm/accepts/combine responses

If the officials would come asking the organization will also need to produce an audit trail from each message that it handles.

