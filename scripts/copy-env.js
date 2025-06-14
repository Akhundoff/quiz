const fs = require('fs');
const path = require('path');

console.log('⚙️ Setting up environment files...');

const envFiles = [
    { src: '.env.example', dest: '.env' },
    { src: 'backend/.env.example', dest: 'backend/.env' },
    { src: 'frontend/.env.example', dest: 'frontend/.env' }
];

envFiles.forEach(({ src, dest }) => {
    if (!fs.existsSync(dest)) {
        if (fs.existsSync(src)) {
            fs.copyFileSync(src, dest);
            console.log(`✅ Created ${dest} file`);
        } else {
            console.log(`⚠️ ${src} not found, skipping ${dest}`);
        }
    } else {
        console.log(`⚠️ ${dest} file already exists`);
    }
});

console.log('✅ Environment setup completed!');