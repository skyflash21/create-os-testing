<?php

namespace App\Providers;

use App\Actions\Jetstream\AddTeamMember;
use App\Actions\Jetstream\CreateTeam;
use App\Actions\Jetstream\DeleteTeam;
use App\Actions\Jetstream\DeleteUser;
use App\Actions\Jetstream\InviteTeamMember;
use App\Actions\Jetstream\RemoveTeamMember;
use App\Actions\Jetstream\UpdateTeamName;
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

        Jetstream::createTeamsUsing(CreateTeam::class);
        Jetstream::updateTeamNamesUsing(UpdateTeamName::class);
        Jetstream::addTeamMembersUsing(AddTeamMember::class);
        Jetstream::inviteTeamMembersUsing(InviteTeamMember::class);
        Jetstream::removeTeamMembersUsing(RemoveTeamMember::class);
        Jetstream::deleteTeamsUsing(DeleteTeam::class);
        Jetstream::deleteUsersUsing(DeleteUser::class);
    }

    /**
     * Configure the roles and permissions that are available within the application.
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

        Jetstream::role('admin', 'Administrator', [
            // Administrator permission
            'computer_os:view_team_computer'
        ])->description('Administrator users can perform any action.');
    }
}
