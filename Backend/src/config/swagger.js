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
      },
      AdminKeyAuth: {
        type: 'apiKey',
        in: 'header',
        name: 'x-admin-key'
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
                    database: {
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
    },
    '/admin/specialties': {
      get: {
        tags: ['Admin'],
        summary: 'Lista especialidades cadastradas',
        security: [
          {
            BearerAuth: []
          },
          {
            AdminKeyAuth: []
          }
        ],
        parameters: [
          {
            in: 'query',
            name: 'includeInactive',
            schema: {
              type: 'boolean'
            },
            required: false,
            description: 'Quando true, inclui especialidades inativas.'
          }
        ],
        responses: {
          200: {
            description: 'Especialidades listadas com sucesso'
          }
        }
      },
      post: {
        tags: ['Admin'],
        summary: 'Cria uma nova especialidade',
        security: [
          {
            BearerAuth: []
          },
          {
            AdminKeyAuth: []
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name'],
                properties: {
                  name: {
                    type: 'string',
                    example: 'Elétrica residencial'
                  },
                  description: {
                    type: 'string',
                    example: 'Instalação e manutenção elétrica.'
                  },
                  isActive: {
                    type: 'boolean',
                    example: true
                  }
                }
              }
            }
          }
        },
        responses: {
          201: {
            description: 'Especialidade criada com sucesso'
          }
        }
      }
    },
    '/admin/specialties/{id}': {
      put: {
        tags: ['Admin'],
        summary: 'Atualiza uma especialidade',
        security: [
          {
            BearerAuth: []
          },
          {
            AdminKeyAuth: []
          }
        ],
        parameters: [
          {
            in: 'path',
            name: 'id',
            required: true,
            schema: {
              type: 'string',
              format: 'uuid'
            }
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  name: {
                    type: 'string',
                    example: 'Hidráulica'
                  },
                  description: {
                    type: 'string',
                    example: 'Serviços hidráulicos em geral.'
                  },
                  isActive: {
                    type: 'boolean',
                    example: true
                  }
                }
              }
            }
          }
        },
        responses: {
          200: {
            description: 'Especialidade atualizada com sucesso'
          }
        }
      },
      delete: {
        tags: ['Admin'],
        summary: 'Remove uma especialidade',
        security: [
          {
            BearerAuth: []
          },
          {
            AdminKeyAuth: []
          }
        ],
        parameters: [
          {
            in: 'path',
            name: 'id',
            required: true,
            schema: {
              type: 'string',
              format: 'uuid'
            }
          }
        ],
        responses: {
          200: {
            description: 'Especialidade removida com sucesso'
          }
        }
      }
    }
  }
};