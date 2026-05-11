export const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'Projeto LAMD 2026 1 API',
    version: '1.0.0',
    description: 'API do app de atendimento de chamados com roteamento por região.'
  },
  servers: [
    {
      url: 'http://localhost:3000',
      description: 'Servidor local'
    }
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT'
      }
    }
  },
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Verifica se a API está online',
        responses: {
          200: {
            description: 'API saudável',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    status: {
                      type: 'string',
                      example: 'ok'
                    },
                    timestamp: {
                      type: 'string',
                      example: '2026-05-05T12:00:00.000Z'
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    '/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Cria uma conta de cliente ou parceiro',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                oneOf: [
                  {
                    type: 'object',
                    required: ['program', 'name', 'email', 'password'],
                    properties: {
                      program: {
                        type: 'string',
                        enum: ['customer', 'cliente'],
                        example: 'customer'
                      },
                      name: {
                        type: 'string',
                        example: 'Maria Silva'
                      },
                      email: {
                        type: 'string',
                        example: 'maria@exemplo.com'
                      },
                      password: {
                        type: 'string',
                        example: 'SenhaForte123'
                      },
                      phone: {
                        type: 'string',
                        example: '+55 11 99999-9999'
                      }
                    }
                  },
                  {
                    type: 'object',
                    required: ['program', 'companyName', 'document', 'email', 'password'],
                    properties: {
                      program: {
                        type: 'string',
                        enum: ['partner', 'parceiro'],
                        example: 'partner'
                      },
                      companyName: {
                        type: 'string',
                        example: 'Soluções Silva LTDA'
                      },
                      document: {
                        type: 'string',
                        example: '12.345.678/0001-90'
                      },
                      email: {
                        type: 'string',
                        example: 'parceiro@exemplo.com'
                      },
                      password: {
                        type: 'string',
                        example: 'SenhaForte123'
                      },
                      phone: {
                        type: 'string',
                        example: '+55 11 98888-7777'
                      },
                      bio: {
                        type: 'string',
                        example: 'Atendimento elétrico e hidráulico.'
                      },
                      specialties: {
                        oneOf: [
                          { type: 'array', items: { type: 'string' } },
                          { type: 'string' }
                        ],
                        example: ['elétrica', 'hidráulica']
                      }
                    }
                  }
                ]
              }
            }
          }
        },
        responses: {
          201: {
            description: 'Conta criada com sucesso'
          }
        }
      }
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Autentica uma conta e retorna JWT',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['program', 'email', 'password'],
                properties: {
                  program: {
                    type: 'string',
                    enum: ['customer', 'partner', 'cliente', 'parceiro'],
                    example: 'customer'
                  },
                  email: {
                    type: 'string',
                    example: 'maria@exemplo.com'
                  },
                  password: {
                    type: 'string',
                    example: 'SenhaForte123'
                  }
                }
              }
            }
          }
        },
        responses: {
          200: {
            description: 'Autenticado com sucesso'
          }
        }
      }
    },
    '/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Retorna a conta autenticada',
        security: [
          {
            BearerAuth: []
          }
        ],
        responses: {
          200: {
            description: 'Conta autenticada'
          }
        }
      }
    }
  }
};