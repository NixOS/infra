# Ordering Services
#
# Given a set of services, make them run one at a time in a specific
# order, on a timer.
{ }:
{
  # Given a list of systemd service, give each one an After
  # attribute, so they start in a specific order. The returned
  # list can be converted in to a systemd.services attrset with
  # `lib.listToAttrs`.
  #
  # Example:
  #
  #  mkOrderedChain [
  #    { name = "foo"; value = { script = "true"; }; }
  #    { name = "bar"; value = { script = "true"; }; }
  #  ]
  #
  # => [
  #  {
  #    name = "foo";
  #    value = {
  #      script = "true";
  #      unitConfig = { After = []; };
  #    };
  #  }
  #  {
  #    name = "bar";
  #    value = {
  #      script = "true";
  #      unitConfig = { After = [ "bar" ]; };
  #    };
  #  }
  #
  mkOrderedChain =
    jobs:
    let
      unitConfigFrom = job: job.unitConfig or { };
      afterFrom = job: (unitConfigFrom job).After or [ ];
      previousFrom = collector: if collector ? previous then [ collector.previous ] else [ ];

      ordered = builtins.foldl' (collector: item: {
        services = collector.services ++ [
          {
            inherit (item) name;
            value = item.value // {
              unitConfig = (unitConfigFrom item.value) // {
                After = (afterFrom item.value) ++ (previousFrom collector);
              };
            };
          }
        ];
        previous = "${item.name}.service";
      }) { services = [ ]; } jobs;
    in
    ordered.services;
}
