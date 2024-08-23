<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('computers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('description')->nullable();
            $table->foreignId('personal_access_token_id')->nullable()->constrained('personal_access_tokens')->onDelete('set null');
            $table->timestamps();
            $table->enum('type', ['turtle', 'pocket', 'computer']);
            $table->boolean('is_advanced');
            $table->enum('wireless_modem_side', ['left', 'right', 'front', 'back', 'up', 'down','none']);
            $table->timestamp('last_used_at')->nullable();
            $table->integer('used_disk_space')->default(0);
            $table->integer('total_disk_space');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('computers');
    }
};
