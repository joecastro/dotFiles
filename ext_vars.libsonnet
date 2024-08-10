{
    home: std.extVar('home'),
    cwd: std.extVar('cwd'),
    is_osx: std.extVar('kernel') == 'darwin',
    is_localhost: std.extVar('is_localhost') == 'true',
    hostname: std.extVar('hostname')
}