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
        Schema::create('files', function (Blueprint $table) {
            $table->string('path')->primary();
            $table->string('name');
            $table->text('description')->nullable(); // Ajout d'une colonne description
            $table->string('hash');
            $table->unsignedBigInteger('size');
            $table->timestamps();
        });

        Schema::create('file_versions', function (Blueprint $table) {
            $table->id();
            $table->string('file_path');
            $table->binary('content');
            $table->unsignedInteger('version');
            $table->timestamps();

            // Définition de la clé étrangère vers la table files, la primary key de files est path
            $table->foreign('file_path')->references('path')->on('files');
            
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('files');
        Schema::dropIfExists('file_versions');
    }
};
