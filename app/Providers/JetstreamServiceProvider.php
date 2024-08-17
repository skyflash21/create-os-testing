<?php

namespace App\Providers;

use App\Actions\Jetstream\DeleteUser;
use Illuminate\Support\ServiceProvider;
use Laravel\Jetstream\Jetstream;

class JetstreamServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configurePermissions();

        Jetstream::deleteUsersUsing(DeleteUser::class);
    }

    /**
     * Configure the permissions that are available within the application.
     */
    protected function configurePermissions(): void
    {
        Jetstream::defaultApiTokenPermissions(['read']);

        Jetstream::permissions([
            // Permissions lié au utilisateur
            'user_management:delete_users',
            'user_management:add_users',
            'user_management:edit_users',
            'user_management:view_users',

            // Permissions lié au usines
            'factory_management:delete_factories',
            'factory_management:add_factories',
            'factory_management:edit_factories',
            'factory_management:view_factories',
            
            // Permissions lié au stockage
            'storage_management:delete_storages',
            'storage_management:add_storages',
            'storage_management:edit_storages',
            'storage_management:view_storages',
        ]);
    }
}
