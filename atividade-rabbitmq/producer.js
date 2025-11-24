const express = require('express');
const amqp = require('amqplib');

const app = express();
app.use(express.json());

const EXCHANGE_NAME = 'shopping_events';
const ROUTING_KEY = 'list.checkout.completed';

async function connectRabbitMQ() {
    const connection = await amqp.connect('amqp://localhost');
    const channel = await connection.createChannel();
    
    // Cria o Exchange do tipo 'topic' (permite uso de curingas como #)
    await channel.assertExchange(EXCHANGE_NAME, 'topic', { durable: false });
    
    return channel;
}

// Endpoint de Checkout
app.post('/lists/:id/checkout', async (req, res) => {
    const listId = req.params.id;
    const { userEmail, totalAmount } = req.body; // Simulando dados vindo no body

    try {
        const channel = await connectRabbitMQ();
        
        const message = {
            listId,
            userEmail,
            totalAmount,
            timestamp: new Date().toISOString()
        };

        // 1. Publica a mensagem no Exchange
        channel.publish(EXCHANGE_NAME, ROUTING_KEY, Buffer.from(JSON.stringify(message)));
        
        console.log(`[Producer] Mensagem enviada: list.checkout.completed para Lista ${listId}`);

        // 2. Resposta Imediata (Assíncrono)
        res.status(202).json({ 
            status: 'accepted', 
            message: 'Checkout iniciado. Você receberá um email em breve.' 
        });

        // Fecha a conexão após um breve tempo (apenas para este exemplo simples)
        setTimeout(() => channel.connection.close(), 500);

    } catch (error) {
        console.error(error);
        res.status(500).send('Erro interno ao conectar na fila');
    }
});

app.listen(3000, () => {
    console.log('🛒 List Service rodando na porta 3000');
});
