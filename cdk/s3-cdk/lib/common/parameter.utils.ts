import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class ParameterExporter {

    scopeRef :Construct;
    idRef: string;
    propsRef: cdk.CfnOutputProps;

    public static scope(scope:Construct): ParameterExporter {
        let exporter = new ParameterExporter();
        exporter.scopeRef = scope;
        return exporter;
    }

    public id(id: string): ParameterExporter {
        this.idRef = id;
        return this;
    }

    public props(props: cdk.CfnOutputProps): ParameterExporter {
        this.propsRef = props;
        return this;
    }

    public create(): cdk.CfnOutput {
        if (!this.idRef) {
            throw Error('The id argument is mandatory.');
        }
        if (!this.propsRef) {
            throw Error('The props argument is mandatory.');
        }
        return new cdk.CfnOutput(this.scopeRef, this.idRef, this.propsRef);
    }
}