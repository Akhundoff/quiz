import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { AdminUser } from '../../entities/admin-user.entity';

@Injectable()
export class DatabaseService implements OnModuleInit {
    constructor(
        @InjectRepository(AdminUser)
        private adminUserRepository: Repository<AdminUser>,
    ) {}

    async onModuleInit() {
        await this.createDefaultAdmin();
    }

    private async createDefaultAdmin() {
        const existingAdmin = await this.adminUserRepository.findOne({
            where: { username: 'admin' },
        });

        if (!existingAdmin) {
            const hashedPassword = await bcrypt.hash('admin123', 10);
            const admin = this.adminUserRepository.create({
                username: 'admin',
                passwordHash: hashedPassword,
            });

            await this.adminUserRepository.save(admin);
            console.log('✅ Default admin user created (username: admin, password: admin123)');
        }
    }
}