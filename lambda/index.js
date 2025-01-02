const AWS = require('aws-sdk');
const sns = new AWS.SNS();

exports.handler = async (event) => {
    try {
        // Procesar mensaje de SQS
        const record = event.Records[0];
        const message = JSON.parse(record.body);
        
        // Procesar el mensaje (aquí puedes agregar tu lógica)
        const processedMessage = {
            originalMessage: message,
            timestamp: new Date().toISOString(),
            status: 'processed'
        };
        
        // Publicar resultado en SNS
        await sns.publish({
            TopicArn: process.env.SNS_TOPIC_ARN,
            Message: JSON.stringify(processedMessage),
            Subject: 'Message Processed'
        }).promise();
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Message processed successfully'
            })
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
};