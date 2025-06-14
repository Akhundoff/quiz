import { Entity, PrimaryGeneratedColumn, Column, OneToMany, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UserResponse } from './user-response.entity';

@Entity('questions')
export class Question {
    @PrimaryGeneratedColumn()
    id: number;

    @Column('text')
    text: string;

    @Column({
        type: 'enum',
        enum: ['radio', 'checkbox', 'text'],
    })
    type: 'radio' | 'checkbox' | 'text';

    @Column('json', { nullable: true })
    options: string[];

    @Column({ default: true })
    required: boolean;

    @Column({ name: 'order_number' })
    orderNumber: number;

    @Column({ name: 'is_active', default: true })
    isActive: boolean;

    @OneToMany(() => UserResponse, response => response.question)
    responses: UserResponse[];

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
