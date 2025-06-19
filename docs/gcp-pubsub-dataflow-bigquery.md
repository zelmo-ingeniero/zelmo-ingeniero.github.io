
# GCP Cloud Shell commands to connect a pub/sub to a BigQuery

This create the required permissions to the GCP project

```bash
gcloud config list --format 'value(core.account)'

gcloud config set project <your-gcp-project>

gcloud services enable compute.googleapis.com dataflow.googleapis.com logging.googleapis.com bigquery.googleapis.com pubsub.googleapis.com storage.googleapis.com cloudresourcemanager.googleapis.com cloudscheduler.googleapis.com

gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:<your-service-account>" --role=roles/dataflow.admin
gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:<your-service-account>" --role=roles/dataflow.worker
gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:<your-service-account>" --role=roles/storage.admin
gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:<your-service-account>" --role=roles/pubsub.editor
gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:<your-service-account>" --role=roles/bigquery.dataEditor
```

Create an Storage bucket for the dataflow

```bash
gcloud storage buckets create gs://bucket-pubsub-bigquery
```

Create the pub/sub topic and suscription

```bash
gcloud pubsub topics create first-pubsub-topic

gcloud pubsub subscriptions create --topic first-pubsub-topic first-pubsub-subc
```

Craate the BigQuery dataset with a table (in this case the table is called "tutorial")

```bash
bq --location=northamerica-south1 mk <your-gcp-project>:tutorial_dataset
bq mk --table <your-gcp-project>:tutorial_dataset.tutorial url:STRING,review:STRING
```

Then create the Dataflow:

 - `gcs-location` is the public template for the Dataflow writted by GCP
 - `staging-location` is the recently created bucket storage
 - `parameters` are the input and output to the Dataflow, in this case the input is the pub/sub subscription and the output is the BigQuery table

```bash
gcloud dataflow jobs run first-dataflow-pubsub-bigquery \
    --gcs-location gs://dataflow-templates-northamerica-south1/latest/PubSub_Subscription_to_BigQuery \
    --region <your-location> \
    --staging-location gs://bucket-pubsub-bigquery/temp \
    --parameters \
inputSubscription=projects/<your-gcp-project>/subscriptions/first-pubsub-subc,\
outputTableSpec=<your-gcp-project>:tutorial_dataset.tutorial
```

Validate that all was correctly created by sending messages to the pub/sub and watching if the message is stored in the BigQuery table (The message content must follow the table columns)

```bash
gcloud pubsub topics publish first-pubsub-topic --message='{"url": "https://beam.apache.org/documentation/sdks/java/", "review": "positive"}'
```

View the data in the BigQuery table

```bash
bq query --use_legacy_sql=false 'SELECT * FROM `'"<your-gcp-project>.tutorial_dataset.tutorial"'`'
```

## How to send messages with NodeJS

What if you want to send messages from code instad of running `gcloud pubsub topics publish first-pubsub-topic --message='{"url": "https://beam.apache.org/documentation/sdks/java/", "review": "positive"}'`? then follow this steps:

Create a service account and assign to it the "Pub/Sub Publisher Account" role

```bash
gcloud iam service-accounts create pubsub-publisher --project <your-gcp-project> --display-name "Pub/Sub Publisher Account"

gcloud projects add-iam-policy-binding <your-gcp-project> --member="serviceAccount:$(gcloud iam service-accounts list --filter="displayName:Pub/Sub Publisher Account" --format='value(email)')" --role="roles/pubsub.publisher"
```

Create the key to the service account and store the JSON file in a safe place. That JSON file should be downloaded in the place where the NodeJS code is running

```bash
gcloud iam service-accounts keys create ~/pubsub-publisher-key.json \
    --iam-account="$(gcloud iam service-accounts list --filter="displayName:Pub/Sub Publisher Account" --format='value(email)')" \
    --project <your-gcp-project>
```

Then in the code install the next library

```bash
npm install @google-cloud/pubsub
```

And export the environment variable `GOOGLE_APPLICATION_CREDENTIALS` and its value will be the path to the JSON file

```bash
GOOGLE_APPLICATION_CREDENTIALS="/home/myuser/gcp/pubsub-publisher-key.json" node app.js
```

This an example of how to use the library to send a message

```js
const { PubSub } = require('@google-cloud/pubsub');

async function publishMessage() {
  // Creates a client; cache this for further use.
  const pubSubClient = new PubSub({ projectId: '<your-gcp-project>' }); // Ensure GOOGLE_APPLICATION_CREDENTIALS is set or keyFilename is provided

  const topicName = 'first-pubsub-topic';
  const message = {
    data: Buffer.from(JSON.stringify({ url: 'http://hello', review: 'positive' })),
  };

  try {
    const messageId = await pubSubClient.topic(topicName).publishMessage(message);
    console.log(`Message ${messageId} published.`);
  } catch (error) {
    console.error(`Received error while publishing: ${error}`);
    throw error;
  }
}

publishMessage();
```