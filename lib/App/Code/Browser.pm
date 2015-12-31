package App::Code::Browser;

use Archive::Extract;
use File::Basename;
use Dancer2;
use Data::Dumper;
use Cwd;
use File::Temp qw{tempdir};
use File::Fetch;

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
    my $archive = Archive::Extract->new( archive => $uploaded );
    mkdir $toPath;
    $archive->extract(to => $toPath);
    debug "Extracted to:" . $archive->extract_path;
};

sub getRemote {
    my $url = shift;
    my $ff = File::Fetch->new(uri => $url);
    my $tempname = $ff->fetch(to => tempdir()) || die "Couldn't fetch $url!";
    return $tempname;
};

sub getViewables {
    my $prefix = shift // "";
    my $path = "$DATA_DIR/$prefix";
    opendir(my $dh, $path) || die "Error reading $path!";
    # Drop only . because it's useless and messes stuff up
    sort map { s/^\///gr } 
         map { "$prefix/$_" } 
         grep { !/^\.$/ } 
         readdir $dh;
};

get '/' => sub {
    my %templateVars = (
        entries => [ getViewables() ],
    );
    my $here = getcwd;
    debug "You are $here";
    template('index', \%templateVars);
};

post '/upload' => sub {
    delayed {
        my $name = param('projname');
        my $tarUpload = upload('tarball');
        my $tarPath = "";
        my $url = param('url');

        debug "Url: $url";
        debug "Name: $name";
        debug Dumper(request->uploads);
        debug Dumper(request->params);
        debug Dumper(upload('tarball'));

        die "Must specify exactly one of URL or file upload." 
            unless defined($tarUpload) || defined($url);

        content "Resolving tar file...";
        flush;

        if (!$tarUpload) {
            debug "Going to start download...";
            $tarPath = getRemote($url);
            debug "Done!";
        } else {
            # Must have gotten an archive uploaded
            $tarPath = $tarUpload->tempname;
        }

        $tarPath || die "Something went wrong finding your upload.";

        content "Done resolving tar file.";
        content "Uploading... $name";
        flush;

        untar($tarPath, $name);

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

sub renderDir {
    my $relpath = shift;
    my $templateArgs = {
        entries => [ getViewables($relpath) ],
    };

    template("dir", $templateArgs);
}

get '/view/**' => sub {
    # We don't need to sanitize because '/view/..' is interpeted as '/'
    my ($pathElementRef) = splat;
    my $relpath = join("/", @{$pathElementRef});
    my $path = inData($relpath);
    debug $path;

    if (-T $path) {
        debug "I'm a file! $path";
        return renderFile($relpath, $path);
    } elsif (-d $path) {
        debug "I'm a directory! $path";
        return renderDir($relpath);
    } else {
        # TODO(pscollins): Strictly speaking this is a vulnerability
        send_error "Tried to view the wrong kind of thing @ $path", 404;
    }
};


true;
