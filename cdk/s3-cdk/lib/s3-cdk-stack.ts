import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';
import { ParameterExporter } from './common/parameter.utils';

export interface S3StackProps extends cdk.StackProps {
  bucketName: string;
  publicAccess?: boolean;
}

export class S3CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: S3StackProps) {
    super(scope, id, props);
    const bucket = new s3.Bucket(this, props?.bucketName || "");

    if (props?.publicAccess) {
      bucket.grantPublicAccess();
    }

    ParameterExporter.scope(this)
                    .id(`${props?.bucketName}Arn`)
                    .props({ 
                      value: bucket.bucketArn,
                      exportName: `${props?.bucketName}Arn`,
                      description: `Stack output parameter for the Arn name of ${props?.bucketName} bucket.` 
                    })
                    .create();
  }


}
