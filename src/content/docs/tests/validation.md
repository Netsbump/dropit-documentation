---
title: Validation des composants
description: Processus de validation des différents composants
---

## Tests unitaires du PermissionsGuard

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { EntityManager } from '@mikro-orm/core';
import { PermissionsGuard } from './permissions.guard';
import { Member } from '../../domain/organization/member.entity';

describe('PermissionsGuard', () => {
  let guard: PermissionsGuard;
  let reflector: Reflector;
  let entityManager: EntityManager;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PermissionsGuard,
        {
          provide: Reflector,
          useValue: {
            get: jest.fn(),
          },
        },
        {
          provide: EntityManager,
          useValue: {
            findOne: jest.fn(),
          },
        },
      ],
    }).compile();

    guard = module.get<PermissionsGuard>(PermissionsGuard);
    reflector = module.get<Reflector>(Reflector);
    entityManager = module.get<EntityManager>(EntityManager);
  });

  it('should allow access when user has required permissions', async () => {
    // Mock du contexte d'exécution
    const mockContext = createMockExecutionContext({
      user: { id: 'user-1' },
      session: { activeOrganizationId: 'org-1' },
    });

    // Mock des permissions requises
    jest.spyOn(reflector, 'get').mockReturnValue(['read']);

    // Mock du membre avec rôle admin
    jest.spyOn(entityManager, 'findOne').mockResolvedValue({
      role: 'admin',
    } as Member);

    const result = await guard.canActivate(mockContext);
    expect(result).toBe(true);
  });

  it('should deny access when user lacks required permissions', async () => {
    const mockContext = createMockExecutionContext({
      user: { id: 'user-1' },
      session: { activeOrganizationId: 'org-1' },
    });

    jest.spyOn(reflector, 'get').mockReturnValue(['delete']);

    // Mock du membre avec rôle member (pas de permission delete)
    jest.spyOn(entityManager, 'findOne').mockResolvedValue({
      role: 'member',
    } as Member);

    await expect(guard.canActivate(mockContext)).rejects.toThrow();
  });

  // ... autres tests
});

function createMockExecutionContext(sessionData: any): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({
        session: sessionData,
      }),
    }),
    getClass: () => ({ name: 'WorkoutController' }),
    getHandler: () => ({}),
  } as ExecutionContext;
}
```