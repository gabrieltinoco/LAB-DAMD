const amqp = require('amqplib');

const EXCHANGE_NAME = 'shopping_events';
const QUEUE_NAME = 'notification_queue'; // Fila específica para notificações
const ROUTING_KEY_PATTERN = 'list.checkout.#';

async function startConsumer() {
    try {
        const connection = await amqp.connect('amqp://localhost');
        const channel = await connection.createChannel();

        // Garante que o Exchange existe
        await channel.assertExchange(EXCHANGE_NAME, 'topic', { durable: false });

        // Garante que a Fila existe e conecta ela ao Exchange (Bind)
        // Exclusive: false garante que se o script cair e voltar, a fila continua lá
        await channel.assertQueue(QUEUE_NAME, { exclusive: false });
        
        // A mágica acontece aqui: Ligar a fila ao Exchange com a chave correta
        await channel.bindQueue(QUEUE_NAME, EXCHANGE_NAME, ROUTING_KEY_PATTERN);

        console.log('📧 Notification Service aguardando mensagens...');

        channel.consume(QUEUE_NAME, (msg) => {
            if (msg) {
                const content = JSON.parse(msg.content.toString());
                
                // Lógica de Negócio (Simulada)
                console.log(`\n[Notification] 📨 Enviando comprovante da lista ${content.listId} para o usuário ${content.userEmail}`);
                
                // ACK: Confirma para o RabbitMQ que processou com sucesso
                channel.ack(msg);
            }
        });

    } catch (error) {
        console.error(error);
    }
}

startConsumer();
