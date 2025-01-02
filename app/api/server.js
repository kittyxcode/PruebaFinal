const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const winston = require('winston');
const app = express();
const port = 3000;

// Configuración de logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'techwave-api' },
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Simulación de métricas
function generateMetrics() {
  return {
    cpu: Math.floor(Math.random() * 100),
    memory: Math.floor(Math.random() * 100),
    disk: Math.floor(Math.random() * 100)
  };
}

// Endpoints
app.get('/api/metrics', (req, res) => {
  const metrics = generateMetrics();
  logger.info('Metrics requested', { metrics });
  res.json(metrics);
});

app.post('/api/alert', (req, res) => {
  logger.warn('Alert received', { alert: req.body });
  res.json({ status: 'Alert received', timestamp: new Date().toISOString() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Error occurred', { error: err });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(port, () => {
  logger.info(`API running on port ${port}`);
});