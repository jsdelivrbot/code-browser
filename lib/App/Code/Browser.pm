package App::Code::Browser;
use Dancer2;
use Data::Dumper;
use Cwd;

our $VERSION = '0.1';

# TODO(pscollins): this should probably go in config.yaml
my $DATA_DIR = getcwd . "/data";

get '/' => sub {
    my %templateVars = (
        files => [
            "foo",
            "bar", 
            "baz",
        ],
    );
    my $here = getcwd;
    debug "You are $here";
    template('index', \%templateVars);
};

post '/upload' => sub {
    my $ps = request->params();
    debug Dumper($ps);
    return 'This will display the upload progress for ' . $ps->{'projname'};
};

true;
