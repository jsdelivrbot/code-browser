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
    # Kill duplicate . to stop paths like ../../
    my $toPath = inData($projname =~ s/\.+/\./gr);
    debug $toPath;
    my $archive = Archive::Extract->new(archive => $uploaded->tempname);
    mkdir $toPath;
    $archive->extract(to => $toPath);
    debug "Extracted to:" . $archive->extract_path;
};

sub getViewables {
    my $path = "$DATA_DIR/" . (shift // "");
    opendir(my $dh, $path) || die "Error reading $path!";
    grep { !/^\./ } readdir $dh;
};

get '/' => sub {
    my %templateVars = (
        files => [ getViewables() ],
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

sub renderFile {
    my ($relpath, $abspath) = @_;
    open my $fh, '<', $abspath or die "Can't open: $abspath";    
    my $templateArgs = {
        relpath => $relpath,
        filecontents => do { local $/; <$fh> },
    };
    template("code", $templateArgs);
};

get '/view/**' => sub {
    # We don't need to sanitize because '/view/..' is interpeted as '/'
    my ($pathElementRef) = splat;
    my $relpath = join("/", @{$pathElementRef});
    my $path = inData($relpath);
    debug $path;

    if (-f $path) {
        debug "I'm a file! $path";
        return renderFile($relpath, $path);
    } elsif (-d $path) {
        return "I'm a directory! $path";
    } else {
        # TODO(pscollins): Strictly speaking this is a vulnerability
        send_error "Tried to view the wrong kind of thing @ $path", 404;
    }
};


true;
