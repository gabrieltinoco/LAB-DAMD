const amqp = require('amqplib');

const EXCHANGE_NAME = 'shopping_events';
const QUEUE_NAME = 'analytics_queue'; // Nome DIFERENTE para garantir que receba cópia
const ROUTING_KEY_PATTERN = 'list.checkout.#';

async function startConsumer() {
    try {
        const connection = await amqp.connect('amqp://localhost');
        const channel = await connection.createChannel();

        await channel.assertExchange(EXCHANGE_NAME, 'topic', { durable: false });
        await channel.assertQueue(QUEUE_NAME, { exclusive: false });
        await channel.bindQueue(QUEUE_NAME, EXCHANGE_NAME, ROUTING_KEY_PATTERN);

        console.log('📈 Analytics Service aguardando dados...');

        channel.consume(QUEUE_NAME, (msg) => {
            if (msg) {
                const content = JSON.parse(msg.content.toString());
                
                // Lógica de Negócio
                console.log(`\n[Analytics] 💰 Processando estatísticas. Total gasto: R$ ${content.totalAmount}`);
                
                channel.ack(msg);
            }
        });

    } catch (error) {
        console.error(error);
    }
}

startConsumer();
