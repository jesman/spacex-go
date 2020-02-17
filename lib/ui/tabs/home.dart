import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:provider/provider.dart';
import 'package:row_collection/row_collection.dart';

import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../util/menu.dart';
import '../../util/photos.dart';
import '../pages/index.dart';
import '../widgets/index.dart';

/// This tab holds main information about the next launch.
/// It has a countdown widget.
class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  ScrollController _controller;
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()
      ..addListener(() => setState(() => _offset = _controller.offset));
  }

  Widget _headerDetails(BuildContext context, Launch launch) {
    final double _sliverHeight =
        MediaQuery.of(context).size.height * SliverBar.heightRatio;

    // When user scrolls 10% height of the SliverAppBar,
    // header countdown widget will dissapears.
    return launch != null &&
            MediaQuery.of(context).orientation != Orientation.landscape
        ? AnimatedOpacity(
            opacity: _offset > _sliverHeight / 10 ? 0.0 : 1.0,
            duration: Duration(milliseconds: 350),
            child: launch.launchDate.isAfter(DateTime.now()) &&
                    !launch.isDateTooTentative
                ? LaunchCountdown(launch.launchDate)
                : launch.hasVideo && !launch.isDateTooTentative
                    ? InkWell(
                        onTap: () => FlutterWebBrowser.openWebPage(
                          url: launch.getVideo,
                          androidToolbarColor: Theme.of(context).primaryColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.play_arrow, size: 50),
                            Text(
                              FlutterI18n.translate(
                                context,
                                'spacex.home.tab.live_mission',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontFamily: 'RobotoMono',
                                shadows: <Shadow>[
                                  Shadow(
                                    offset: const Offset(0, 0),
                                    blurRadius: 4,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Separator.none(),
          )
        : Separator.none();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LaunchesRepository>(
      builder: (context, model, child) => Scaffold(
        body: SliverPage<LaunchesRepository>.display(
          controller: _controller,
          title: FlutterI18n.translate(context, 'spacex.home.title'),
          opacity: model.nextLaunch?.isDateTooTentative == true &&
                  MediaQuery.of(context).orientation != Orientation.landscape
              ? 1.0
              : 0.64,
          counter: _headerDetails(context, model.nextLaunch),
          slides: List.from(SpaceXPhotos.home)..shuffle(),
          popupMenu: Menu.home,
          body: <Widget>[
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<LaunchesRepository>(
      builder: (context, model, child) => Column(children: <Widget>[
        ListCell.icon(
          icon: Icons.public,
          trailing: Icon(Icons.chevron_right),
          title: model.vehicle(context),
          subtitle: model.payload(context),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LaunchPage(model.nextLaunch.number),
            ),
          ),
        ),
        Separator.divider(indent: 72),
        ListCell.icon(
          icon: Icons.event,
          trailing: Icon(Icons.chevron_right),
          title: FlutterI18n.translate(
            context,
            'spacex.home.tab.date.title',
          ),
          subtitle: model.launchDate(context),
          onTap: () async {
            if (await Add2Calendar.addEvent2Cal(
              Event(
                title: model.nextLaunch.name,
                description: model.nextLaunch.details ??
                    FlutterI18n.translate(
                      context,
                      'spacex.launch.page.no_description',
                    ),
                location: model.nextLaunch.launchpadName,
                startDate: model.nextLaunch.launchDate,
                endDate: model.nextLaunch.launchDate.add(
                  Duration(minutes: 30),
                ),
              ),
            )) {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event added to the calendar'),
                ),
              );
            } else {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error while trying to add the event'),
                ),
              );
            }
          },
        ),
        Separator.divider(indent: 72),
        ListCell.icon(
          icon: Icons.location_on,
          trailing: Icon(Icons.chevron_right),
          title: FlutterI18n.translate(
            context,
            'spacex.home.tab.launchpad.title',
          ),
          subtitle: model.launchpad(context),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<LaunchpadRepository>(
                create: (_) => LaunchpadRepository(
                  model.nextLaunch.launchpadId,
                  model.nextLaunch.launchpadName,
                ),
                child: LaunchpadPage(),
              ),
              fullscreenDialog: true,
            ),
          ),
        ),
        Separator.divider(indent: 72),
        ListCell.icon(
          icon: Icons.timer,
          title: FlutterI18n.translate(
            context,
            'spacex.home.tab.static_fire.title',
          ),
          subtitle: model.staticFire(context),
        ),
        Separator.divider(indent: 72),
        if (model.nextLaunch.rocket.hasFairing)
          ListCell.icon(
            icon: Icons.directions_boat,
            title: FlutterI18n.translate(
              context,
              'spacex.home.tab.fairings.title',
            ),
            subtitle: model.fairings(context),
          )
        else
          AbsorbPointer(
            absorbing:
                model.nextLaunch.rocket.secondStage.getPayload(0).capsuleSerial ==
                    null,
            child: ListCell.svg(
              context: context,
              image: 'assets/icons/capsule.svg',
              trailing: Icon(
                Icons.chevron_right,
                color: model.nextLaunch.rocket.secondStage
                            .getPayload(0)
                            .capsuleSerial ==
                        null
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).brightness == Brightness.light
                        ? Colors.black45
                        : Colors.white,
              ),
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.capsule.title',
              ),
              subtitle: model.capsule(context),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<CapsuleRepository>(
                    create: (_) => CapsuleRepository(
                      model.nextLaunch.rocket.secondStage
                          .getPayload(0)
                          .capsuleSerial,
                    ),
                    child: CapsulePage(),
                  ),
                  fullscreenDialog: true,
                ),
              ),
            ),
          ),
        Separator.divider(indent: 72),
        AbsorbPointer(
          absorbing: model.nextLaunch.rocket.isFirstStageNull,
          child: ListCell.svg(
            context: context,
            image: 'assets/icons/fins.svg',
            trailing: Icon(
              Icons.chevron_right,
              color: model.nextLaunch.rocket.isFirstStageNull
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).brightness == Brightness.light
                      ? Colors.black45
                      : Colors.white,
            ),
            title: FlutterI18n.translate(
              context,
              'spacex.home.tab.first_stage.title',
            ),
            subtitle: model.firstStage(context),
            onTap: () => model.nextLaunch.rocket.isHeavy
                ? showHeavyDialog(context, model)
                : openCorePage(
                    context,
                    model.nextLaunch.rocket.getSingleCore.id,
                  ),
          ),
        ),
        Separator.divider(indent: 72),
        AbsorbPointer(
          absorbing: model.nextLaunch.rocket.getSingleCore.landingZone == null,
          child: ListCell.icon(
            icon: Icons.center_focus_weak,
            trailing: Icon(
              Icons.chevron_right,
              color: model.nextLaunch.rocket.getSingleCore.landingZone == null
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).brightness == Brightness.light
                      ? Colors.black45
                      : Colors.white,
            ),
            title: FlutterI18n.translate(
              context,
              'spacex.home.tab.landing.title',
            ),
            subtitle: model.landing(context),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider<LandpadRepository>(
                  create: (_) => LandpadRepository(
                    model.nextLaunch.rocket.getSingleCore.landingZone,
                  ),
                  child: LandpadPage(),
                ),
                fullscreenDialog: true,
              ),
            ),
          ),
        ),
        Separator.divider(indent: 72)
      ]),
    );
  }

  void showHeavyDialog(BuildContext context, LaunchesRepository model) {
    showDialog(
      context: context,
      builder: (context) => RoundDialog(
        title: FlutterI18n.translate(
          context,
          'spacex.home.tab.first_stage.heavy_dialog.title',
        ),
        children: [
          for (final core in model.nextLaunch.rocket.firstStage)
            AbsorbPointer(
              absorbing: core.id == null,
              child: ListCell(
                title: core.id != null
                    ? FlutterI18n.translate(
                        context,
                        'spacex.dialog.vehicle.title_core',
                        {'serial': core.id},
                      )
                    : FlutterI18n.translate(
                        context,
                        'spacex.home.tab.first_stage.heavy_dialog.core_null_title',
                      ),
                subtitle: model.core(context, core),
                onTap: () => openCorePage(
                  context,
                  core.id,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
              ),
            )
        ],
      ),
    );
  }

  void openCorePage(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<CoreRepository>(
          create: (_) => CoreRepository(id),
          child: CoreDialog(),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
