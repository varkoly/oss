# LMD Module to manage Application Rights
# Copyright (c) 2012 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.
BEGIN{ push @INC,"/usr/share/oss/lib/"; }

package ApplicationRights;

use strict;
use oss_base;
use oss_LDAPAttributes;
use oss_utils;
use Storable qw(thaw freeze);
use MIME::Base64;
use vars qw(@ISA);
@ISA = qw(oss_base);

sub new
{
    my $this    = shift;
    my $connect = shift || undef;
    my $self    = oss_base->new($connect);
    return bless $self, $this;
}

sub interface
{
	return [
		"getCapabilities",
		"default",
		"toggle",
		"filetree_dir_open",
		"toggleall"
	];

}

sub getCapabilities
{
	return [
		{ title        => 'Manage Application Rights' },
		{ type         => 'command' },
		{ allowedRole  => 'root' },
		{ allowedRole  => 'sysadmins' },
		{ category     => 'Settings' },
                { order        => 30 },
		{ variable     =>  [ "apps",   [ type => "filetree", label=>"Applications", can_choose_dir => "true" ] ]  }
	];
}

sub filetree_dir_open
{
	my $this   = shift;
	my $reply  = shift;
	$this->default($reply);
}

sub default
{
	my $this   = shift;
	my $reply  = shift;
	my @modules= ();
	my $MENU   = thaw(decode_base64(main::GetSessionDatas('MODULES','BASE')));
	my $apps   = '<dir lanbel="'.main::__("Roles").'" path="roles">'."\n";

	foreach my $role ( keys %{$MENU} )
	{
		$apps   .= '  <dir label="'.main::__($role)."\" path=\"roles/$role\">\n";
		foreach my $cat ( keys %{$MENU->{$role}} )
		{
			if( main::isDenied("r","$role","C:$cat") || main::isDenied("r","*","C:$cat") )
			{
				$apps   .= '    <dir label="('.main::__($cat).")\" path=\"$role|C:$cat\">\n";
			}
			else
			{
				$apps   .= '    <dir label="'.main::__($cat)."\" path=\"$role|C:$cat\">\n";
				foreach my $mod ( keys %{$MENU->{$role}->{$cat}} )
				{
					if( main::isDenied("r","$role","$mod") || main::isDenied("r","*","$mod") )
					{
						$apps   .= '      <dir label="('.main::__($mod).")\" path=\"$role|$mod\">\n";
					}
					else
					{
						$apps   .= '      <dir label="'.main::__($mod)."\" path=\"$role|$mod\">\n";
					}
					$apps   .= "      </dir>\n";
				}
			}
			$apps   .= "    </dir>\n";
		}
		$apps   .= "  </dir>\n";
	}
	$apps .= '</dir>';
	my @ret = ( { apps      => $apps } );
print STDERR $reply->{apps}."\n";
	if( defined $reply->{apps} && $reply->{apps} =~ /\|/ )
	{
		push @ret, { rightaction    => 'toggle' };
		push @ret, { rightaction    => 'toggleall' };
	}
	return \@ret;
}


sub toggle
{
	my $this   = shift;
	my $reply  = shift;
	my ( $role , $dest ) = split( /\|/,$reply->{apps} );

	if( main::isDenied("r","$role","$dest") )
	{
		main::delRight("r","$role","$dest");
	}
	else
	{
		main::addRight("r","$role","$dest","n");
	}
	$this->default();
}

sub toggleall
{
	my $this   = shift;
	my $reply  = shift;
	my ( $role , $dest ) = split( /\|/,$reply->{apps} );

	if( main::isDenied("r","*","$dest") )
	{
		main::delRight("r","*","$dest");
	}
	else
	{
		main::addRight("r","*","$dest","n");
	}
	$this->default();
}
1;
