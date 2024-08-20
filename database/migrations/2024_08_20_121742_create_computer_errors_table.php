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
        Schema::create('computer_errors', function (Blueprint $table) {
            $table->id();
            $table->timestamps();

            // Foreign key to the files table
            $table->unsignedBigInteger('file_id');
            $table->foreign('file_id')->references('id')->on('files')->onDelete('cascade');

            // Specify the file's version
            $table->unsignedInteger('version');

            // Specify the line number where the error occurred
            $table->unsignedInteger('line_number');

            // Specify the error message
            $table->text('error_message');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('computer_errors');
    }
};
