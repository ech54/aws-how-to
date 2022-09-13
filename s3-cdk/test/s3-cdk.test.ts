import {Match, Template} from 'aws-cdk-lib/assertions';
import * as cdk from 'aws-cdk-lib/core';
import { S3CdkStack } from '../lib/s3-cdk-stack';

describe('Test on the S3 cdk stack', () => {

    test('S3 Bucket Created', () => {
        const template = Template.fromStack(new S3CdkStack(new cdk.App(), "s3-cdk-for-test", { bucketName: "s3-test"}));

        //console.log(template.toJSON());

        // Check existing bucket
        template.resourceCountIs("AWS::S3::Bucket", 1);

        // Check output properties
        const s3ArnOutput = template.findOutputs("s3testArn");
        //console.log(s3ArnOutput);
        expect(s3ArnOutput.s3testArn.Description).toEqual('Stack output parameter for the Arn name of s3-test bucket.')
        expect(s3ArnOutput.s3testArn.Export.Name).toEqual('s3-testArn')
    });
        

})
