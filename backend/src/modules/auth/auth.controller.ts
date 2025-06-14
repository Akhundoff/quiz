import { Controller, Post, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBody } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LocalAuthGuard } from './local-auth.guard';
import { LoginDto } from './dto/auth.dto';

@ApiTags('Auth')
@Controller('admin')
export class AuthController {
    constructor(private authService: AuthService) {}

    @UseGuards(LocalAuthGuard)
    @Post('login')
    @ApiOperation({ summary: 'Admin login' })
    @ApiBody({ type: LoginDto })
    async login(@Request() req) {
        return this.authService.login(req.user);
    }
}