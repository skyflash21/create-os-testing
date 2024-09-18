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
            $table->string('file_path')->primary();
            $table->string('name');
            $table->text('description')->nullable(); // Ajout d'une colonne description
            $table->boolean('is_restricted')->default(false);
            $table->timestamps();
        });

        Schema::create('file_versions', function (Blueprint $table) {
            $table->id();
            $table->string('file_path');
            $table->binary('content');
            $table->text('change_note')->nullable();
            $table->boolean('is_restricted')->default(false);
            $table->unsignedInteger('version');
            $table->unsignedBigInteger('size');
            $table->string('hash')->index(); // Ajout d'un index pour améliorer les recherches par hash
            $table->timestamps();

            // Clé étrangère vers la table files (corrected reference)
            $table->foreign('file_path')
                  ->references('file_path')
                  ->on('files')
                  ->onDelete('cascade'); // Suppression en cascade si le fichier est supprimé
            
            // Contrainte d'unicité pour éviter plusieurs versions identiques d'un fichier
            $table->unique(['file_path', 'version', 'hash']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('file_versions');
        Schema::dropIfExists('files');
    }
};
