import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { S3CdkStack } from '../lib/s3-cdk-stack';

const app = new cdk.App();

new S3CdkStack(app, 's3-cdk-stack', {
  bucketName: "sample-s3",
  publicAccess: true
});