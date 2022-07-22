<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Sendportal\Base\SendportalBaseServiceProvider;

class PublicVendorAssets extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'sp:publish';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->callSilent(
            'vendor:publish',
            [
                '--provider' => SendportalBaseServiceProvider::class,
                '--tag' => 'sendportal-assets',
                '--force' => true
            ]
        );
        return 0;
    }
}
