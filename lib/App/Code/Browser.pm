package App::Code::Browser;

use Archive::Extract;
use File::Basename;
use Dancer2;
use Data::Dumper;
use Cwd;

our $VERSION = '0.1';

# TODO(pscollins): this should probably go in config.yaml
my $DATA_DIR = getcwd . "/data";

sub inData {
    my $end = shift;
    "$DATA_DIR/$end";
};

sub untar {
    my ($uploaded, $projname) = @_;
    my $toPath = inData($projname);
    debug $toPath;
    # Need to preprocess in case we got something with ..
    my $archive = Archive::Extract->new(archive => $uploaded->tempname);
    mkdir $toPath;
    $archive->extract(to => $toPath);
    debug "Extracted to:" . $archive->extract_path;
};

sub getDirectories {
    opendir(my $dh, $DATA_DIR) || die "Error reading $DATA_DIR!";
    grep { !/^\./ && -d "$DATA_DIR/$_" } readdir $dh;
};

get '/' => sub {
    my %templateVars = (
        files => [ getDirectories() ],
    );
    my $here = getcwd;
    debug "You are $here";
    template('index', \%templateVars);
};

post '/upload' => sub {
    delayed {
        my $name = param('projname');
        my $tar = upload('tarball');
        debug Dumper(request->uploads);
        debug Dumper(request->params);
        debug Dumper(upload('tarball'));
        debug "Name: $name";

        content "Uploading... $name";
        flush;

        untar($tar, $name);
        content 'Done!';

        done;
    }
};

get '/view/**' => sub {
    # We don't need to sanitize because '/view/..' is interpeted as '/'
    my ($pathElementRef) = splat;
    my @pathElements = @{$pathElementRef};
    my $path = inData(join("/", @pathElements));
    debug $path;
    return $path;
};


true;
