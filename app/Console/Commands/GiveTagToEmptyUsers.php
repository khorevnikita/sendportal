<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Sendportal\Base\Models\Subscriber;
use Sendportal\Base\Models\Tag;

class GiveTagToEmptyUsers extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'empty_users:tag';

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
        $subscribers = Subscriber::query()->doesntHave('tags')->pluck('id');
        $tag = Tag::where("name", 'mailchimp')->first();
        $tag->subscribers()->attach($subscribers);
        return 0;
    }
}
